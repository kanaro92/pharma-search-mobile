import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pharmacy.dart';
import '../models/medication_request.dart';
import '../models/chat_message.dart';
import '../models/message.dart';
import '../models/medication_inquiry.dart';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isInitialized = false;

  ApiService({String baseUrl = 'http://localhost:8080'})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 3),
          validateStatus: (status) => status! < 500,
        )),
        _storage = const FlutterSecureStorage() {
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    if (_isInitialized) return;
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    _isInitialized = true;
  }

  Future<void> setAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> clearAuthToken() async {
    await _storage.delete(key: 'auth_token');
    _dio.options.headers.remove('Authorization');
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        await _storage.write(key: 'auth_token', value: token);
        _dio.options.headers['Authorization'] = 'Bearer $token';
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _dio.options.headers.remove('Authorization');
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  Future<List<Pharmacy>> getNearbyPharmacies(Position position) async {
    await _initializeAuth();
    try {
      debugPrint('Fetching nearby pharmacies at (${position.latitude}, ${position.longitude})');
      final response = await _dio.get(
        '/api/pharmacies/nearby',
        queryParameters: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'radius': 5000, // 5km radius
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => Pharmacy.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch nearby pharmacies: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('DioError fetching nearby pharmacies:');
      debugPrint('  Type: ${e.type}');
      debugPrint('  Message: ${e.message}');
      debugPrint('  Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('Error fetching nearby pharmacies: $e');
      rethrow;
    }
  }

  Future<List<Pharmacy>> searchPharmacies(String query) async {
    await _initializeAuth();
    try {
      debugPrint('Searching pharmacies with query: $query');
      final response = await _dio.get(
        '/api/pharmacies/search',
        queryParameters: {'query': query},
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => Pharmacy.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search pharmacies: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('DioError searching pharmacies:');
      debugPrint('  Type: ${e.type}');
      debugPrint('  Message: ${e.message}');
      debugPrint('  Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('Error searching pharmacies: $e');
      rethrow;
    }
  }

  Future<List<String>> searchMedications(String query) async {
    await _initializeAuth();
    try {
      final response = await _dio.get(
        '/api/medications/search',
        queryParameters: {'query': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => json.toString()).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Please login to search medications');
      } else {
        throw Exception('Failed to search medications');
      }
    } catch (e) {
      debugPrint('Error searching medications: $e');
      rethrow;
    }
  }

  Future<MedicationRequest> createMedicationRequest(
    String medicationName,
    String? note,
    Pharmacy pharmacy,
  ) async {
    await _initializeAuth();
    try {
      final response = await _dio.post(
        '/api/medication-requests',
        data: {
          'medicationName': medicationName,
          'note': note,
          'pharmacyId': pharmacy.id,
        },
      );

      if (response.statusCode == 201) {
        return MedicationRequest.fromJson(response.data);
      } else {
        throw Exception('Failed to create medication request');
      }
    } catch (e) {
      debugPrint('Error creating medication request: $e');
      rethrow;
    }
  }

  Future<List<Message>> getRequestMessages(int requestId) async {
    await _initializeAuth();
    try {
      final response = await _dio.get('/api/medication-requests/$requestId/messages');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch request messages');
      }
    } catch (e) {
      debugPrint('Error fetching request messages: $e');
      rethrow;
    }
  }

  Future<Message> sendMessage(int requestId, String content) async {
    await _initializeAuth();
    try {
      final response = await _dio.post(
        '/api/medication-requests/$requestId/messages',
        data: {'content': content},
      );

      if (response.statusCode == 201) {
        return Message.fromJson(response.data);
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<MedicationInquiry> createMedicationInquiry(String medicationName, String note) async {
    await _initializeAuth();
    try {
      final response = await _dio.post(
        '/api/medication-inquiries',
        data: {
          'medicationName': medicationName,
          'patientNote': note,
        },
      );

      if (response.statusCode == 201) {
        return MedicationInquiry.fromJson(response.data);
      } else {
        throw Exception('Failed to create medication inquiry');
      }
    } catch (e) {
      debugPrint('Error creating medication inquiry: $e');
      rethrow;
    }
  }

  Future<List<MedicationInquiry>> getMyMedicationInquiries() async {
    await _initializeAuth();
    try {
      final response = await _dio.get('/api/medication-inquiries/my');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => MedicationInquiry.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch medication inquiries');
      }
    } catch (e) {
      debugPrint('Error fetching medication inquiries: $e');
      rethrow;
    }
  }

  Future<List<Message>> getMedicationInquiryMessages(int inquiryId) async {
    await _initializeAuth();
    try {
      final response = await _dio.get('/api/medication-inquiries/$inquiryId/messages');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch inquiry messages');
      }
    } catch (e) {
      debugPrint('Error fetching inquiry messages: $e');
      rethrow;
    }
  }

  Future<Message> sendInquiryMessage(int inquiryId, String content) async {
    await _initializeAuth();
    try {
      final response = await _dio.post(
        '/api/medication-inquiries/$inquiryId/messages',
        data: {'content': content},
      );

      if (response.statusCode == 201) {
        return Message.fromJson(response.data);
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }
}
