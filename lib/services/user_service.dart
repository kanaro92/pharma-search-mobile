import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _currentUser;

  UserService._internal();

  Future<void> setCurrentUser(Map<String, dynamic> user) async {
    _currentUser = user;
    await _storage.write(key: 'current_user', value: json.encode(user));
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    
    final userJson = await _storage.read(key: 'current_user');
    if (userJson != null) {
      _currentUser = json.decode(userJson);
      return _currentUser;
    }
    return null;
  }

  Future<void> clearCurrentUser() async {
    _currentUser = null;
    await _storage.delete(key: 'current_user');
  }

  Future<bool> isPharmacist() async {
    final user = await getCurrentUser();
    return user?['role'] == 'PHARMACIST';
  }

  Future<bool> isUser() async {
    final user = await getCurrentUser();
    return user?['role'] == 'USER';
  }

  Future<String?> getUserRole() async {
    final user = await getCurrentUser();
    return user?['role'];
  }

  Future<String?> getUserName() async {
    final user = await getCurrentUser();
    return user?['name'];
  }

  Future<int?> getUserId() async {
    final user = await getCurrentUser();
    return user?['id'];
  }
}
