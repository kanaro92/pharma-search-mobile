import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  Future<void> initialize() async {
    if (kIsWeb) {
      // Skip Firebase initialization on web
      return;
    }
    
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }
}
