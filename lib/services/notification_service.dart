import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  static const String _channelKey = 'chat_channel';
  static const Color _themeColor = Color(0xFF6B8EB3);

  Future<void> initialize() async {
    // Initialize Awesome Notifications
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_launcher',
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: 'Chat Notifications',
          channelDescription: 'Notifications pour les messages de chat',
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

    // Request notification permissions
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    // Request FCM permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _updateTokenOnServer(token);
    });

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when user taps on notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Listen to notification action buttons
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _handleNotificationAction,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Message reçu en premier plan: ${message.messageId}');
    
    await _showNotification(
      title: message.notification?.title ?? 'Nouveau message',
      body: message.notification?.body ?? '',
      payload: message.data,
      senderName: message.data['senderName'] ?? 'Utilisateur',
      chatId: message.data['chatId'],
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Message reçu en arrière-plan: ${message.messageId}');
    // La navigation sera gérée en fonction du payload
  }

  @pragma('vm:entry-point')
  static Future<void> _handleNotificationAction(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;
    if (payload == null) return;

    switch (receivedAction.buttonKeyPressed) {
      case 'REPLY':
        // Ouvrir l'écran de réponse avec le chatId
        print('Ouvrir la réponse pour le chat: ${payload['chatId']}');
        break;
      case 'VIEW':
        // Ouvrir l'écran de chat
        print('Ouvrir le chat: ${payload['chatId']}');
        break;
      default:
        // Ouvrir l'écran de chat par défaut
        print('Action par défaut pour le chat: ${payload['chatId']}');
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    required String senderName,
    required String chatId,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecond,
        channelKey: _channelKey,
        title: title,
        body: body,
        payload: {
          ...payload,
          'chatId': chatId,
          'senderName': senderName,
        },
        notificationLayout: NotificationLayout.Default,
        color: _themeColor,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Répondre',
          enabled: true,
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'VIEW',
          label: 'Voir',
          enabled: true,
          autoDismissible: true,
        ),
      ],
    );
  }

  Future<void> _updateTokenOnServer(String token) async {
    // TODO: Implement API call to update FCM token on your backend
    // This should be implemented to match your backend API
  }

  String? get fcmToken => _fcmToken;
}
