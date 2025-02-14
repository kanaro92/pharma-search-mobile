import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to ensure Firebase is initialized here too
  await Firebase.initializeApp();

  print('Handling a background message:');
  print('- Title: ${message.notification?.title}');
  print('- Body: ${message.notification?.body}');
  print('- Data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;
  String? _registeredToken;  // Track which token has been registered
  final Dio _dio = Dio();
  
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    // For Android emulator, use 10.0.2.2 instead of localhost
    if (Platform.isAndroid) {
      final url = 'http://10.0.2.2:8080/api';
      print('Running on Android, using URL: $url');
      return url;
    }
    // For iOS simulator, use localhost
    if (Platform.isIOS) {
      final url = 'http://localhost:8080/api';
      print('Running on iOS, using URL: $url');
      return url;
    }
    // For physical devices, use your computer's IP address
    final url = 'http://192.168.1.27:8080/api';
    print('Running on physical device, using URL: $url');
    return url;
  }

  static const String _channelKey = 'medication_channel';
  static const Color _themeColor = Color(0xFF6B8EB3);

  Future<void> initialize() async {
    if (kIsWeb) {
      print('Notifications are not supported on web platform');
      return;
    }

    try {
      // Initialize Awesome Notifications
      await AwesomeNotifications().initialize(
        null, // no icon for now, can add one later
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic Notifications',
            channelDescription: 'Notification channel for basic notifications',
            defaultColor: const Color(0xFF6B8EB3),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: true,
            enableLights: true,
            enableVibration: true,
          ),
        ],
        debug: true,
      );

      // Request notification permissions
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        print('Requesting notification permission...');
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      // Set up Firebase
      await setupFCMListeners();
      
      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
      print('Error details: ${e.toString()}');
    }
  }

  Future<void> requestPermission() async {
    if (kIsWeb) {
      print('Notifications are not supported on web platform');
      return;
    }
    
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    try {
      print('Showing notification:');
      print('- Title: $title');
      print('- Body: $body');
      print('- Payload: $payload');

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: title,
          body: body,
          payload: payload,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Message,
        ),
      );
      print('Notification created successfully');
    } catch (e) {
      print('Error showing notification: $e');
      print('Error details: ${e.toString()}');
    }
  }

  Future<void> setupNotificationListeners() async {
    if (kIsWeb) return;

    await AwesomeNotifications().setListeners(
      onNotificationCreatedMethod: (receivedNotification) async {
        print('Notification created: ${receivedNotification.title}');
      },
      onNotificationDisplayedMethod: (receivedNotification) async {
        print('Notification displayed: ${receivedNotification.title}');
      },
      onActionReceivedMethod: (receivedAction) async {
        print('Notification action received: ${receivedAction.title}');
        // Gérer l'action de notification ici
        if (receivedAction.payload != null) {
          // Traiter les données du payload
          print('Payload: ${receivedAction.payload}');
        }
      },
      onDismissActionReceivedMethod: (receivedAction) async {
        print('Notification dismissed: ${receivedAction.title}');
      },
    );
  }

  Future<void> setupFCMListeners() async {
    if (kIsWeb) {
      print('Notifications are not supported on web platform');
      return;
    }

    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print('Initializing Firebase...');
        await Firebase.initializeApp();
      }

      // Request permissions first
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('User granted permission: ${settings.authorizationStatus}');

      // Configure FCM to handle messages when app is in foreground
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get the token
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        print('Registering FCM token with backend...');
        await _registerFcmTokenWithBackend(_fcmToken!);
        _registeredToken = _fcmToken;
      } else {
        print('Failed to get FCM token');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('FCM token refreshed: $newToken');
        if (newToken != _fcmToken) {  // Only register if token actually changed
          _fcmToken = newToken;
          await _registerFcmTokenWithBackend(newToken);
          _registeredToken = newToken;
        } else {
          print('Token unchanged, skipping registration: $newToken');
        }
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('Received foreground message:');
        print('- Title: ${message.notification?.title}');
        print('- Body: ${message.notification?.body}');
        print('- Data: ${message.data}');
        
        // Create a notification when in foreground
        await showNotification(
          title: message.notification?.title ?? 'Nouveau message',
          body: message.notification?.body ?? '',
          payload: message.data.map((key, value) => MapEntry(key, value.toString())),
        );
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle when user taps on notification when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('User tapped on notification:');
        print('- Title: ${message.notification?.title}');
        print('- Body: ${message.notification?.body}');
        print('- Data: ${message.data}');
        _handleNotificationTap(message.data);
      });
      
      print('FCM listeners setup completed');
    } catch (e) {
      print('Error setting up FCM listeners: $e');
      print('Error details: ${e.toString()}');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // TODO: Implement navigation based on notification type
    print('Handling notification tap with data: $data');
    // Example:
    // if (data['type'] == 'medication_search') {
    //   // Navigate to medication search details
    // }
  }

  Future<void> _registerFcmTokenWithBackend(String token) async {
    try {
      final authToken = await _getAuthToken();
      if (authToken == null) {
        print('Cannot register FCM token: No auth token found');
        return;
      }

      print('Sending FCM token to backend...');
      final response = await _dio.post(
        '$_baseUrl/notifications/token',
        data: {'token': token},
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        print('FCM token registered successfully with backend');
      } else {
        print('Failed to register FCM token with backend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error registering FCM token with backend: $e');
      print('Error details: ${e.toString()}');
      if (e is DioException) {
        print('Request details:');
        print('- URL: ${e.requestOptions.uri}');
        print('- Headers: ${e.requestOptions.headers}');
        print('- Data: ${e.requestOptions.data}');
      }
    }
  }

  Future<String?> _getAuthToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'auth_token');
  }

  // Méthode de test pour simuler une notification de demande de médicament
  Future<void> testMedicationRequest({
    String medicationName = 'Paracétamol',
    String userName = 'John Doe',
  }) async {
    if (kIsWeb) {
      print('Notifications are not supported on web platform');
      return;
    }

    final payload = {
      'type': 'medication_request',
      'medication': medicationName,
      'user': userName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await showNotification(
      title: 'Nouvelle demande de médicament',
      body: '$userName recherche du $medicationName',
      payload: payload,
    );
  }

  // Méthode pour envoyer une notification de demande de médicament réelle
  Future<void> sendMedicationRequestNotification({
    required String medicationName,
    required String userName,
    required String pharmacyName,
    int? requestId,
  }) async {
    if (kIsWeb) return;

    final payload = {
      'type': 'medication_request',
      'medication': medicationName,
      'user': userName,
      'pharmacy': pharmacyName,
      'request_id': requestId?.toString() ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    };

    await showNotification(
      title: 'Nouvelle demande de médicament',
      body: '$userName recherche du $medicationName à la pharmacie $pharmacyName',
      payload: payload,
    );
  }

  Future<void> testNotification() async {
    print('Testing notification...');
    try {
      // Test FCM notification
      print('Current FCM token: $_fcmToken');
      
      // Test local notification
      await showNotification(
        title: 'Test Notification',
        body: 'This is a test notification from PharmaSearch',
        payload: {'type': 'test'},
      );
      print('Local notification sent successfully');
    } catch (e) {
      print('Error sending test notification: $e');
      print('Error details: ${e.toString()}');
    }
  }
}
