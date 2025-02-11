import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'YOUR_API_KEY',
        appId: 'YOUR_APP_ID',
        messagingSenderId: 'YOUR_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
      );
    }
    
    throw UnsupportedError(
      'DefaultFirebaseOptions are not configured for this platform.',
    );
  }
}
