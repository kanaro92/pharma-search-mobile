import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  static const String _channelKey = 'medication_channel';
  static const Color _themeColor = Color(0xFF6B8EB3);

  Future<void> initialize() async {
    if (kIsWeb) {
      print('Notifications are not supported on web platform');
      return;
    }

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
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
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
