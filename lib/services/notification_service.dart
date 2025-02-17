import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import '../screens/pharmacist_inquiry_detail_screen.dart';
import '../models/medication_inquiry.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Global navigator key to use for navigation from anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  static const String _channelKey = 'basic_channel';
  static const Color _themeColor = Color(0xFF6B8EB3);
  final Set<String> _processedNotificationIds = {};  // Track processed notifications
  bool _isShowingNotification = false;  // Add lock to prevent concurrent shows

  Future<void> initialize() async {
    if (kIsWeb) {
      print('Notifications are not supported on web platform');
      return;
    }

    try {
      // Initialize Awesome Notifications with a single channel
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: _channelKey,
            channelName: 'Basic Notifications',
            channelDescription: 'Notification channel for all notifications',
            defaultColor: _themeColor,
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: true,
            enableLights: true,
            enableVibration: true,
          ),
        ],
        debug: true,
      );

      // Register the global action receiver
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
      );

      await setupFCMListeners();
    } catch (e) {
      print('Error initializing notification service: $e');
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
      // Use a lock to prevent concurrent notification shows
      if (_isShowingNotification) {
        print('Already showing a notification, skipping');
        return;
      }
      _isShowingNotification = true;

      final String notificationId = payload?['notification_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Check if this notification has already been processed
      if (_processedNotificationIds.contains(notificationId)) {
        print('Notification already processed, skipping: $notificationId');
        _isShowingNotification = false;
        return;
      }

      print('Showing notification:');
      print('- ID: $notificationId');
      print('- Title: $title');
      print('- Body: $body');
      print('- Payload: $payload');

      // Generate a simple numeric ID for Awesome Notifications
      final simpleId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: simpleId,
          channelKey: _channelKey,
          title: title,
          body: body,
          payload: {...?payload, 'notification_id': notificationId},
          notificationLayout: NotificationLayout.Default,
        ),
      );

      // Add to processed notifications
      _processedNotificationIds.add(notificationId);

      // Clean up old notification IDs (keep only last 100)
      if (_processedNotificationIds.length > 100) {
        _processedNotificationIds.remove(_processedNotificationIds.first);
      }

      print('Notification created successfully');
    } catch (e) {
      print('Error showing notification: $e');
    } finally {
      _isShowingNotification = false;
    }
  }

  Future<void> setupFCMListeners() async {
    if (kIsWeb) return;

    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Request permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');

      // Completely disable FCM's native notifications
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      // Get and register FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await _registerFcmTokenWithBackend(_fcmToken!);
        _registeredToken = _fcmToken;
      }

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        if (newToken != _registeredToken) {
          await _registerFcmTokenWithBackend(newToken);
          _registeredToken = newToken;
        }
      });

      // Handle foreground messages with debouncing
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final String notificationId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

        // Show notification with proper deduplication
        await showNotification(
          title: message.notification?.title ?? 'Nouveau message',
          body: message.notification?.body ?? '',
          payload: {
            ...message.data,
            'notification_id': notificationId,
            'message_type': 'foreground'
          },
        );
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message.data);
      });

    } catch (e) {
      print('Error setting up FCM listeners: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) async {
    print('Handling notification tap with data: $data');

    if (data['type'] == 'medication_search') {
      final requestId = int.parse(data['request_id']);
      final apiService = ApiService();

      try {
        // Get the inquiry messages
        //final messages = await apiService.getMedicationInquiryMessages(requestId);

        // Create a MedicationInquiry object with the data from the notification
        final inquiry = MedicationInquiry(
          id: requestId,
          medicationName: data['medication_name'],
          patientNote: data['patient_note'],  // This will be updated when messages are loaded
          status: 'PENDING',  // Default status
          createdAt: DateTime.now(),
          user: {
            'id': int.parse(data['user_id']),
            'name': data['user_name'],
          },
         // messages: messages,
        );

        final context = NotificationService.navigatorKey.currentContext;
        if (context != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PharmacistInquiryDetailScreen(
                apiService: apiService,
                inquiry: inquiry,
              ),
            ),
          );
        }
      } catch (e) {
        print('Error handling notification tap: $e');
      }
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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to ensure Firebase is initialized here too
  await Firebase.initializeApp();

  print('Handling a background message:');
  print('- Title: ${message.notification?.title}');
  print('- Body: ${message.notification?.body}');
  print('- Data: ${message.data}');
}

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  print('Notification action received: ${receivedAction.toMap().toString()}');
  final NotificationService service = NotificationService();
  service._handleNotificationTap(receivedAction.payload ?? {});
}
