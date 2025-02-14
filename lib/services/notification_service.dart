import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

    // Reset the registered token on initialization
    _registeredToken = null;
    _fcmToken = null;

    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: 'Medication Notifications',
          channelDescription: 'Notifications pour les demandes de médicaments',
          defaultColor: _themeColor,
          ledColor: _themeColor,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableLights: true,
          enableVibration: true,
          playSound: true,
        )
      ],
    );

    await requestPermission();
    await setupNotificationListeners();
    await setupFCMListeners();
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
    if (kIsWeb) {
      print('Notifications are not supported on web platform');
      return;
    }
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: _channelKey,
          title: title,
          body: body,
          payload: payload,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Message,
        ),
      );
    } catch (e) {
      print('Error showing notification: $e');
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
      await _firebaseMessaging.requestPermission(
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

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
      print('FCM listeners setup completed');
    } catch (e) {
      print('Error setting up FCM listeners: $e');
    }
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

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.notification?.title}');
    
    // Convertir Map<String, dynamic> en Map<String, String>
    final payload = message.data.map((key, value) => MapEntry(key, value.toString()));
    
    await showNotification(
      title: message.notification?.title ?? 'Nouveau message',
      body: message.notification?.body ?? '',
      payload: payload,
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Message reçu en arrière-plan: ${message.messageId}');
    // La navigation sera gérée en fonction du payload
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
}
