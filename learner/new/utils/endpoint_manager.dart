// Service to manage endpoint configuration changes
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:writeright/new/utils/constants.dart';

class EndpointConfigurationManager {
  static EndpointConfigurationManager? _instance;
  static EndpointConfigurationManager get instance =>
      _instance ??= EndpointConfigurationManager._();

  EndpointConfigurationManager._();

  // Callbacks to notify when endpoint changes
  final List<VoidCallback> _changeCallbacks = [];

  // Current Dio instance
  Dio? _currentDio;

  // Get current Dio instance
  Dio? get currentDio => _currentDio;

  // Initialize with a Dio instance
  void initialize(Dio dio) {
    _currentDio = dio;
  }

  // Add a callback to be notified when endpoint changes
  void addChangeCallback(VoidCallback callback) {
    _changeCallbacks.add(callback);
  }

  // Remove a callback
  void removeChangeCallback(VoidCallback callback) {
    _changeCallbacks.remove(callback);
  }

  // Notify all callbacks that endpoint has changed
  void notifyEndpointChanged() {
    for (final callback in _changeCallbacks) {
      callback();
    }
  }

  // Refresh the Dio configuration with new endpoint
  Future<void> refreshDioConfiguration(
    SharedPreferences sharedPreferences,
  ) async {
    if (_currentDio != null) {
      // Clear constants cache
      AppConstants.clearCache();

      // Get new base URL
      final newBaseUrl = await AppConstants.baseUrl;

      // Update the Dio instance's base URL
      _currentDio!.options.baseUrl = newBaseUrl;

      // Force close existing connections to ensure fresh connections with new URL
      try {
        _currentDio!.close(force: true);
      } catch (e) {
        // Ignore errors when closing connections
      }

      // Notify all dependent services
      notifyEndpointChanged();
    }
  }
}
