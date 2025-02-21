import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/pharmacy.dart';
import '../models/message.dart';
import '../models/medication_request.dart';
import '../models/medication_inquiry.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import 'user_service.dart';

class ApiService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static Future<bool> get _isEmulator async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return !androidInfo.isPhysicalDevice;
    }
    return false;
  }

  static String? _cachedBaseUrl;
  
  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    
    if (kIsWeb) {
      _cachedBaseUrl = 'http://localhost:8080/api';
      return _cachedBaseUrl!;
    }
    
    // For Android devices
    if (Platform.isAndroid) {
      final isEmulator = await _isEmulator;
      final url = isEmulator 
          ? 'http://10.0.2.2:8080/api'
          : 'http://192.168.1.27:8080/api';
      print('Running on Android ${isEmulator ? "emulator" : "physical device"}, using URL: $url');
      _cachedBaseUrl = url;
      return url;
    }
    
    // For iOS devices
    if (Platform.isIOS) {
      final url = 'http://192.168.1.27:8080/api';
      print('Running on iOS, using URL: $url');
      _cachedBaseUrl = url;
      return url;
    }
    
    // Default fallback
    _cachedBaseUrl = 'http://192.168.1.27:8080/api';
    print('Running on device, using URL: $_cachedBaseUrl');
    return _cachedBaseUrl!;
  }

  // Temporary getter for backward compatibility
  static String get baseUrl {
    if (_cachedBaseUrl == null) {
      // Initialize with a default value
      print('Warning: baseUrl accessed before initialization, using default URL');
      return 'http://192.168.1.27:8080/api';
    }
    return _cachedBaseUrl!;
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isInitialized = false;
  bool _isRefreshing = false;

  ApiService()
      : _storage = const FlutterSecureStorage(),
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          contentType: 'application/json',
        )) {
    print('Initializing ApiService with base URL: ${baseUrl}');
    _dio.options.baseUrl = baseUrl;
    _setupInterceptors();
    _initializeAuth();
  }

  void _setupInterceptors() {
    _dio.interceptors.clear();
    
    // Add logging interceptor
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

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.path.contains('/auth/')) {
            final token = await _storage.read(key: 'auth_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              // Try to refresh the token
              final newToken = await _refreshToken();
              if (newToken != null) {
                // Retry the original request with the new token
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(opts);
                _isRefreshing = false;
                return handler.resolve(response);
              }
            } catch (e) {
              print('Token refresh failed: $e');
              // If refresh fails, clear storage and redirect to login
              await _storage.deleteAll();
              _isRefreshing = false;
              // You might want to add a callback here to notify the UI to show login screen
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _refreshToken() async {
    try {
      final response = await _dio.post('/auth/refresh');
      if (response.statusCode == 200) {
        final token = response.data['token'];
        await _storage.write(key: 'auth_token', value: token);
        return token;
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
    return null;
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

      print('Login response: ${response.data}');  // Debug log

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final token = responseData['token'] as String?;
        final userData = responseData['user'] as Map<String, dynamic>?;

        if (token == null) {
          print('Login error: Token is null');
          return false;
        }

        if (userData == null) {
          print('Login error: User data is null');
          return false;
        }

        await setAuthToken(token);
        await UserService().setCurrentUser(userData);
        
        print('Login successful. User role: ${userData['role']}');
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await clearAuthToken();
    await UserService().clearCurrentUser();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/register',
        data: {
          'name': username,  // Changed from 'username' to 'name' to match backend
          'email': email,
          'password': password,
          'role': role,
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Registration error: $e');
      if (e is DioException && e.response?.data != null) {
        throw e.response?.data['message'] ?? 'Registration failed';
      }
      throw 'Registration failed. Please try again.';
    }
  }

  Future<bool> registerOld(String name, String email, String password) async {
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

  Future<bool> sendMedicationInquiry(String medicationName, String note) async {
    return createMedicationInquiry(medicationName, note);
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

  Future<List<MedicationInquiry>> getPharmacistInquiries() async {
    await _initializeAuth();
    try {
      final response = await _dio.get('/pharmacist/inquiries');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => MedicationInquiry.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch pharmacist inquiries');
      }
    } catch (e) {
      print('Error fetching pharmacist inquiries: $e');
      rethrow;
    }
  }

  Future<MedicationInquiry> respondToInquiry(int inquiryId) async {
    await _initializeAuth();
    try {
      final response = await _dio.post('/medication-inquiries/$inquiryId/respond');
      if (response.statusCode == 200) {
        return MedicationInquiry.fromJson(response.data);
      } else {
        throw Exception('Failed to respond to inquiry');
      }
    } catch (e) {
      print('Error responding to inquiry: $e');
      rethrow;
    }
  }

  Future<void> sendInquiryResponse(int inquiryId, String response) async {
    await _initializeAuth();
    try {
      final body = {
        'content': response,
      };
      await _dio.post('/medication-inquiries/$inquiryId/messages', data: body);
    } catch (e) {
      print('Error sending inquiry response: $e');
      rethrow;
    }
  }

  Future<MedicationInquiry> withdrawFromInquiry(int inquiryId) async {
    await _initializeAuth();
    try {
      final response = await _dio.post('/medication-inquiries/$inquiryId/withdraw');
      if (response.statusCode == 200) {
        return MedicationInquiry.fromJson(response.data);
      } else {
        throw Exception('Failed to withdraw from inquiry');
      }
    } catch (e) {
      print('Error withdrawing from inquiry: $e');
      rethrow;
    }
  }

  Future<Pharmacy> getPharmacyData() async {
    await _initializeAuth();
    try {
      final response = await _dio.get('$baseUrl/pharmacist/pharmacy');
      return Pharmacy.fromJson(response.data);
    } catch (e) {
      print('Error getting pharmacy data: $e');
      rethrow;
    }
  }

  Future<Pharmacy> updatePharmacyData(Map<String, dynamic> data) async {
    await _initializeAuth();
    try {
      final response = await _dio.put(
        '$baseUrl/pharmacist/pharmacy',
        data: data,
      );
      return Pharmacy.fromJson(response.data);
    } catch (e) {
      print('Error updating pharmacy data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPharmacyStatistics() async {
    await _initializeAuth();
    try {
      final response = await _dio.get('$baseUrl/pharmacist/statistics');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting pharmacy statistics: $e');
      rethrow;
    }
  }

  Future<String> getOrCreateConversation(int otherUserId, int? medicationRequestId) async {
    await _initializeAuth();
    try {
      final response = await _dio.post(
        '/conversations',
        data: {
          'otherUserId': otherUserId,
          'medicationRequestId': medicationRequestId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['conversationId'];
      } else {
        throw Exception('Failed to get/create conversation');
      }
    } catch (e) {
      throw Exception('Error getting/creating conversation: $e');
    }
  }

  Future<List<ChatMessage>> getMessages({
    required String conversationId,
    int? medicationRequestId,
  }) async {
    await _initializeAuth();
    try {
      if (medicationRequestId == null) {
        throw Exception('Medication request ID is required');
      }

      final queryParams = {
        'requestId': medicationRequestId.toString(),
        'otherUserId': conversationId,
      };

      final response = await _dio.get(
        '/messages',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Error loading messages: $e');
    }
  }

  Future<ChatMessage> sendChatMessage({
    required String conversationId,
    required int receiverId,
    required String content,
    int? medicationRequestId,
  }) async {
    await _initializeAuth();
    try {
      if (medicationRequestId == null) {
        throw Exception('Medication request ID is required');
      }

      final response = await _dio.post(
        '/messages',
        queryParameters: {
          'requestId': medicationRequestId.toString(),
        },
        data: {
          'content': content,
          'receiverId': receiverId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ChatMessage.fromJson(data);
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }
}
