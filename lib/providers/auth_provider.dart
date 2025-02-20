import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final _storage = const FlutterSecureStorage();
  String? _token;
  bool _isAuthenticated = false;
  String? _userRole;
  final NotificationService _notificationService = NotificationService();

  AuthProvider(this._apiService) {
    _loadToken();
  }

  bool get isAuthenticated => _isAuthenticated;
  String? get userRole => _userRole;

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
    _isAuthenticated = _token != null;
    if (_isAuthenticated) {
      // Only setup FCM listeners if already authenticated
      await _notificationService.setupFCMListeners();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final success = await _apiService.login(email, password);
      if (success) {
        _isAuthenticated = true;
        // Initialize notifications only once after successful login
        if (!_notificationService.isInitialized) {
          print('Login successful, setting up notifications...');
          await _notificationService.initialize();
          await _notificationService.setupFCMListeners();
          print('Notifications setup completed');
        }
        // Register FCM token after successful login
        await _notificationService.registerFCMTokenAfterLogin();
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _storage.delete(key: 'auth_token');
    _token = null;
    _isAuthenticated = false;
    _userRole = null;
    notifyListeners();
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    return await _apiService.register(
      username: username,
      email: email,
      password: password,
      role: role,
    );
  }
}