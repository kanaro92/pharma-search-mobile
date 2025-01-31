import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pharmacy.dart';
import '../models/message.dart';
import '../models/medication_request.dart';
import '../models/medication_inquiry.dart';
import '../models/chat_message.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    // For Android emulator, use 10.0.2.2 instead of localhost
    if (Platform.isAndroid) {
      final url = 'http://10.0.2.2:8080/api';
      print('Running on Android, using URL: $url');
      return url;
    }
    // For iOS simulator, use localhost
    if (Platform.isIOS) {
      final url = 'http://localhost:8080/api';
      print('Running on iOS, using URL: $url');
      return url;
    }
    // For physical devices, use your computer's IP address
    final url = 'http://192.168.1.27:8080/api';
    print('Running on physical device, using URL: $url');
    return url;
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isInitialized = false;

  ApiService()
      : _storage = const FlutterSecureStorage(),
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          contentType: 'application/json',
        )) {
    print('Initializing ApiService with base URL: ${baseUrl}');
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) {
        print('DIO LOG: $object');
      },
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
        '/auth/login',
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
      print('Login error: $e');
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
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<List<Pharmacy>> getNearbyPharmacies(Position position) async {
    await _initializeAuth();
    try {
      print('Fetching nearby pharmacies at (${position.latitude}, ${position.longitude})');
      final response = await _dio.get(
        '/pharmacies/nearby',
        queryParameters: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'radius': 5000, // 5km radius
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => Pharmacy.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch nearby pharmacies: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioError fetching nearby pharmacies:');
      print('  Type: ${e.type}');
      print('  Message: ${e.message}');
      print('  Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Error fetching nearby pharmacies: $e');
      rethrow;
    }
  }

  Future<List<Pharmacy>> searchPharmacies(String query) async {
    await _initializeAuth();
    try {
      print('Searching pharmacies with query: $query');
      final response = await _dio.get(
        '/pharmacies/search',
        queryParameters: {'query': query},
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => Pharmacy.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search pharmacies: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioError searching pharmacies:');
      print('  Type: ${e.type}');
      print('  Message: ${e.message}');
      print('  Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Error searching pharmacies: $e');
      rethrow;
    }
  }

  Future<List<String>> searchMedications(String query) async {
    await _initializeAuth();
    try {
      final response = await _dio.get(
        '/medications/search',
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
      print('Error searching medications: $e');
      rethrow;
    }
  }

  Future<bool> createMedicationRequest(String medicationName, String? note, Pharmacy pharmacy) async {
    await _initializeAuth();
    try {
      print('Creating medication request with pharmacy ID: ${pharmacy.id}');
      final response = await _dio.post(
        '/medication-requests',
        data: {
          'medicationName': medicationName,
          'notes': note,
          'pharmacyId': pharmacy.id,
          'quantity': 1,
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error creating medication request: $e');
      return false;
    }
  }

  Future<List<Message>> getRequestMessages(int requestId) async {
    await _initializeAuth();
    try {
      final response = await _dio.get('/medication-requests/$requestId/messages');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching request messages: $e');
      return [];
    }
  }

  Future<bool> sendMessage(int requestId, String content) async {
    await _initializeAuth();
    try {
      final response = await _dio.post(
        '/medication-requests/$requestId/messages',
        data: {'content': content},
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  Future<bool> createMedicationInquiry(String medicationName, String note) async {
    await _initializeAuth();
    try {
      final response = await _dio.post(
        '/medication-inquiries',
        data: {
          'medicationName': medicationName,
          'patientNote': note,
        },
      );

      print('Create inquiry response: Status ${response.statusCode}, Data: ${response.data}');
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('DioError creating medication inquiry:');
      print('  Type: ${e.type}');
      print('  Message: ${e.message}');
      print('  Response status: ${e.response?.statusCode}');
      print('  Response data: ${e.response?.data}');
      return false;
    } catch (e) {
      print('Error creating medication inquiry: $e');
      return false;
    }
  }

  Future<List<MedicationInquiry>> getMyMedicationInquiries() async {
    await _initializeAuth();
    try {
      final response = await _dio.get('/medication-inquiries/my');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('Fetched inquiries data: $data'); // Debug log
        return data.map((json) {
          try {
            return MedicationInquiry.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            print('Error parsing inquiry: $e');
            print('Problematic JSON: $json');
            rethrow;
          }
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching medication inquiries: $e');
      rethrow;
    }
  }

  Future<List<Message>> getMedicationInquiryMessages(int inquiryId) async {
    await _initializeAuth();
    try {
      print('Fetching messages for inquiry $inquiryId from ${_dio.options.baseUrl}/medication-inquiries/$inquiryId/messages');
      final response = await _dio.get('/medication-inquiries/$inquiryId/messages');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Message.fromJson(json)).toList();
      }
      print('Unexpected status code: ${response.statusCode}');
      return [];
    } on DioException catch (e) {
      print('DioError fetching inquiry messages:');
      print('  Type: ${e.type}');
      print('  Message: ${e.message}');
      print('  Base URL: ${_dio.options.baseUrl}');
      print('  Response status: ${e.response?.statusCode}');
      print('  Response data: ${e.response?.data}');
      return [];
    } catch (e) {
      print('Error fetching inquiry messages: $e');
      return [];
    }
  }

  Future<bool> sendInquiryMessage(int inquiryId, String content) async {
    await _initializeAuth();
    try {
      final response = await _dio.post(
        '/medication-inquiries/$inquiryId/messages',
        data: {'content': content},
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error sending message: $e');
      return false;
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
