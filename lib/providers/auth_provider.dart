import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final _storage = const FlutterSecureStorage();
  String? _token;
  bool _isAuthenticated = false;

  AuthProvider(this._apiService) {
    _loadToken();
  }

  bool get isAuthenticated => _isAuthenticated;

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'token');
    _isAuthenticated = _token != null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final success = await _apiService.login(email, password);
      if (success) {
        _isAuthenticated = true;
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
    await _storage.delete(key: 'token');
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password) async {
    return await _apiService.register(name, email, password);
  }
}
