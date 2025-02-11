import 'notification_service_interface.dart';

class NotificationServiceWeb implements NotificationServiceInterface {
  @override
  Future<void> initialize() async {
    // No-op on web
  }

  @override
  Future<void> handleForegroundMessage(dynamic message) async {
    // No-op on web
  }

  @override
  Future<void> handleBackgroundMessage(dynamic message) async {
    // No-op on web
  }

  @override
  String? get fcmToken => null;
}
