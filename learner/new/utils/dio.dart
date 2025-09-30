import 'package:dio/dio.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class DioProvider {
  static Future<Dio> createDio(
    SharedPreferences sharedPreferences, {
    String? baseUrl,
  }) async {
    // Increase timeout for Android as network calls can be slower
    int timeoutSeconds = AppConstants.timeoutDuration;
    // Longer timeout for Android
    if (!kIsWeb && Platform.isAndroid) timeoutSeconds *= 2;

    baseUrl ??= await AppConstants.baseUrl;

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl, // Base URL
        connectTimeout: Duration(seconds: timeoutSeconds),
        receiveTimeout: Duration(seconds: timeoutSeconds),
        // Only set sendTimeout if not web
        // Workaround for Dio issue on web where sendTimeout is not supported
        // https://github.com/cfug/dio/issues/2255
        sendTimeout: kIsWeb ? Duration.zero : Duration(seconds: timeoutSeconds),
      ),
    );

    // Add interceptors (e.g., for logging or authentication)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authorization token from secure storage
          final authToken = sharedPreferences.getString('sessionKey');
          if (authToken != null) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }

          // If no auth token, still proceed with the request
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.debug(
            'HTTP ${response.statusCode}: ${response.requestOptions.method} ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.error('Dio Error: ${error.type} - ${error.message}');
          AppLogger.error('Request URL: ${error.requestOptions.uri}');
          if (error.response != null) {
            AppLogger.error('Response status: ${error.response?.statusCode}');
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}
