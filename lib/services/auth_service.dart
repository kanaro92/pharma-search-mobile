  import 'package:dio/dio.dart';
import 'user_service.dart';

class AuthenticationError implements Exception {
  final String message;
  final int? statusCode;

  AuthenticationError(this.message, {this.statusCode});

  @override
  String toString() => 'AuthenticationError: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class AuthService {
  final Dio _dio;
  final UserService _userService;
  static const String _baseUrl = 'http://localhost:8080/api';

  AuthService({Dio? dio, UserService? userService})
      : _dio = dio ?? Dio(),
        _userService = userService ?? UserService();

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'];
        final userData = response.data['user'];
        
        // Sauvegarder le token et les données utilisateur
        await _userService.saveAuthToken(token);
        await _userService.setCurrentUser(userData);
      } else {
        throw AuthenticationError(
          'Invalid response from server',
          statusCode: response.statusCode,
        );
      }
    } on DioError catch (e) {
      String errorMessage;
      
      switch (e.type) {
        case DioErrorType.connectionTimeout:
        case DioErrorType.sendTimeout:
        case DioErrorType.receiveTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          break;
        case DioErrorType.badResponse:
          if (e.response?.statusCode == 401) {
            errorMessage = 'Invalid email or password';
          } else {
            errorMessage = e.response?.data?['message'] ?? 'Server error';
          }
          break;
        case DioErrorType.cancel:
          errorMessage = 'Request cancelled';
          break;
        default:
          errorMessage = 'Connection error. Please check your internet connection.';
      }
      
      throw AuthenticationError(
        errorMessage,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw AuthenticationError('An unexpected error occurred');
    }
  }

  Future<void> register(String email, String password, String name, String role) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'role': role,
        },
      );

      if (response.statusCode != 201) {
        throw AuthenticationError(
          'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } on DioError catch (e) {
      String errorMessage;
      
      switch (e.type) {
        case DioErrorType.connectionTimeout:
        case DioErrorType.sendTimeout:
        case DioErrorType.receiveTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          break;
        case DioErrorType.badResponse:
          if (e.response?.statusCode == 409) {
            errorMessage = 'Email already exists';
          } else {
            errorMessage = e.response?.data?['message'] ?? 'Registration failed';
          }
          break;
        case DioErrorType.cancel:
          errorMessage = 'Request cancelled';
          break;
        default:
          errorMessage = 'Connection error. Please check your internet connection.';
      }
      
      throw AuthenticationError(
        errorMessage,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw AuthenticationError('An unexpected error occurred during registration');
    }
  }

  Future<void> logout() async {
    try {
      await _userService.clearCurrentUser();
    } catch (e) {
      throw AuthenticationError('Error during logout');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/reset-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw AuthenticationError(
          'Password reset request failed',
          statusCode: response.statusCode,
        );
      }
    } on DioError catch (e) {
      String errorMessage;
      
      switch (e.type) {
        case DioErrorType.connectionTimeout:
        case DioErrorType.sendTimeout:
        case DioErrorType.receiveTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          break;
        case DioErrorType.badResponse:
          errorMessage = e.response?.data?['message'] ?? 'Password reset failed';
          break;
        case DioErrorType.cancel:
          errorMessage = 'Request cancelled';
          break;
        default:
          errorMessage = 'Connection error. Please check your internet connection.';
      }
      
      throw AuthenticationError(
        errorMessage,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw AuthenticationError('An unexpected error occurred during password reset');
    }
  }
}
