abstract class NotificationServiceInterface {
  Future<void> initialize();
  Future<void> handleForegroundMessage(dynamic message);
  void handleBackgroundMessage(dynamic message);
  String? get fcmToken;
}
