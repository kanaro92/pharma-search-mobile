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
      // Re-initialize notifications if we're already logged in
      await _notificationService.setupFCMListeners();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final success = await _apiService.login(email, password);
      if (success) {
        _isAuthenticated = true;
        // Initialize notifications after successful login
        print('Login successful, setting up notifications...');
        await _notificationService.initialize();  // Initialize first
        await _notificationService.setupFCMListeners();  // Then setup FCM
        print('Notifications setup completed');
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