import 'package:mobile_app/services/notification_service.dart';

void main() async {
  // Initialiser le service de notification
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Envoyer une notification de test
  await notificationService.testMedicationRequest();

  print('Notification de test envoyée !');
}
