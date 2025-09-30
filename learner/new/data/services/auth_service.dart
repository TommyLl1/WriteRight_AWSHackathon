import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/data/models/user.dart';
import 'package:writeright/new/utils/constants.dart';

/// NOTE:
/// I have tried to use secure storage, but it is not working in web.
/// change the storage method if have other solution
/// currently is using session keys, we can use jwt as well

class AuthService {
  final SharedPreferences _sharedPreferences;
  final Dio _dio;

  AuthService(this._sharedPreferences, this._dio);
  Future<void> login({required String email, required String password}) async {
    final baseUrl = await AppConstants.baseUrl;

    try {
      // Make the login request
      AppLogger.info('Attempting to login with email: $email');
      AppLogger.debug('Base URL: $baseUrl');

      AppLogger.apiRequest(
        'POST',
        '$baseUrl/auth/login',
        data: {'email': email, 'password': password},
      );

      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: {'email': email, 'password': password},
      );

      // Check if the response is successful
      if (response.statusCode == 200) {
        final data = response.data;
        final sessionKey = response.headers['Authorization']?.last;

        AppLogger.apiResponse(
          'POST',
          '$baseUrl/auth/login',
          response.statusCode!,
        );
        AppLogger.debug(
          'Session Key received: ${sessionKey != null ? 'Yes' : 'No'}',
        );
        AppLogger.debug('Response data: $data');

        if (sessionKey == null || data == null) {
          throw Exception('Invalid response: Missing session key or user ID');
        }

        // Store the session key and user ID securely
        await _sharedPreferences.setString('sessionKey', sessionKey);
        User user = User.fromJson(data);

        // Add other field if needed
        await _sharedPreferences.setString('userId', user.userId);

        AppLogger.info('Login successful. Session key and user ID stored.');
        AppLogger.userAction(
          'User logged in successfully',
          context: {'userId': user.userId},
        );
      } else {
        AppLogger.apiResponse(
          'POST',
          '$baseUrl/auth/login',
          response.statusCode!,
        );
        throw Exception(
          'Login failed with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      AppLogger.apiError('POST', '$baseUrl/auth/login', e);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Network connection error. Please check your internet connection and ensure the server is running.',
        );
      } else if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid request. Please check your input.');
      }
      throw Exception('Failed to login: ${e.message}');
    } catch (e) {
      AppLogger.error('General login exception', e);
      throw Exception('Failed to login: $e');
    }
  }

  Future<void> logout() async {
    try {
      // Clear the session key and user ID from secure storage and shared preferences
      await _sharedPreferences.remove('sessionKey');
      await _sharedPreferences.remove('userId');
      AppLogger.info('Logout successful. Session key and user ID cleared.');
      AppLogger.userAction('User logged out successfully');
    } catch (e) {
      AppLogger.error('Failed to logout', e);
      throw Exception('Failed to logout: $e');
    }
  }

  Future<String?> getUserId() async {
    return _sharedPreferences.getString('userId');
  }
}
