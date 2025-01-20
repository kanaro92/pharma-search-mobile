import 'package:dio/dio.dart';
import '../models/medication.dart';
import '../models/pharmacy.dart';
import '../models/user.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/medication_request.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl = 'http://192.168.1.27:8080/api';

  ApiService() : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
  }

  Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      String token = response.data['token'];
      print("******************************  Token: $token");
      return token;
    } catch (e) {
      throw Exception('Failed to login');
    }
  }

  Future<List<Medication>> searchMedications(String query) async {
    try {
      final response = await _dio.get('/medications/search', queryParameters: {
        'query': query,
      });
      return (response.data as List)
          .map((json) => Medication.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search medications');
    }
  }

  Future<List<Pharmacy>> findNearbyPharmacies(
      double latitude, double longitude, double radius) async {
    try {
      print("////////////// Request Headers: ${_dio.options.headers}");
      final response = await _dio.get('/pharmacies/nearby', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      });

      return (response.data as List)
          .map((json) => Pharmacy.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to find nearby pharmacies');
    }
  }

  Future<List<ChatMessage>> getMessages(int otherUserId, int? medicationRequestId) async {
    try {
      final queryParams = {
        'otherUserId': otherUserId,
        if (medicationRequestId != null) 'medicationRequestId': medicationRequestId,
      };

      final response = await _dio.get('/messages', queryParameters: queryParams);
      return (response.data as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load messages');
    }
  }

  Future<ChatMessage> sendMessage(int receiverId, String content, int? medicationRequestId) async {
    try {
      final response = await _dio.post('/messages', data: {
        'receiverId': receiverId,
        'content': content,
        if (medicationRequestId != null) 'medicationRequestId': medicationRequestId,
      });
      return ChatMessage.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to send message');
    }
  }

  Future<void> registerFcmToken(String token) async {
    try {
      await _dio.post('/users/fcm-token', data: {
        'token': token,
      });
    } catch (e) {
      throw Exception('Failed to register FCM token');
    }
  }

  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _dio.get('/conversations');
      return (response.data as List)
          .map((json) => Conversation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load conversations');
    }
  }

  Future<List<MedicationRequest>> getMedicationRequests() async {
    try {
      final response = await _dio.get('/medication-requests');
      return (response.data as List)
          .map((json) => MedicationRequest.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load medication requests');
    }
  }

  Future<void> cancelMedicationRequest(int requestId) async {
    try {
      await _dio.post('/medication-requests/$requestId/cancel');
    } catch (e) {
      throw Exception('Failed to cancel medication request');
    }
  }

  void setAuthToken(String token) {
    print("+++++  token: $token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
