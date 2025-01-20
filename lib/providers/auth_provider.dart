import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  final ApiService _apiService;
  final SharedPreferences _prefs;

  AuthProvider(this._apiService, this._prefs) {
    _token = _prefs.getString('token');
    print("+++++ bef provider token: $_token");
    if (_token != null) {

      print("+++++ in provider token: $_token");
      _apiService.setAuthToken(_token!);
    }
  }

  User? get user => _user;
  bool get isAuthenticated => _token != null;
  ApiService get apiService => _apiService;

  Future<void> login(String email, String password) async {
    try {
      final token = await _apiService.login(email, password);
      _token = token;
      print("tokennnnnn : $token");
      await _prefs.setString('token', token);
      _apiService.setAuthToken(token);
      notifyListeners();
    } catch (e) {
      throw Exception('Login failed');
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    await _prefs.remove('token');
    notifyListeners();
  }
}
