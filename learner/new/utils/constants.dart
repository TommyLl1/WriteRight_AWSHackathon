// This file contains constants used throughout the application.

import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  // Cache for staging endpoint preference
  static bool? _useStagingEndpoint;

  // API-related constants
  static Future<String> get baseUrl async {
    // Development
    // return "http://localhost:8000";
    await _loadStagingPreference();

    if (_useStagingEndpoint == true) {
      // Staging
      return "https://hackathonwriteright.myaddr.tools/api-9687094a";
    } else {
      // Production
      return "https://writeright-1.eastasia.cloudapp.azure.com/api-9687094a";
    }

    // if (kIsWeb) {
    //   // For web, use localhost
    // } else if (Platform.isAndroid) {
    //   // For Android emulator, use 10.0.2.2 to reach host machine
    //   return "http://10.0.2.2:8000";
    // } else {
    //   // For iOS simulator and other platforms, use localhost
    //   return "http://localhost:8000";
    // }
  }

  /// TODO: Temporary API URL for image upload testing
  static Future<String> get imagePostAPIUrl async {
    // Using the same base URL as the API for now
    final baseUrl = await AppConstants.baseUrl;
    return "$baseUrl/files/upload";
  }

  static Future<String> get storageBaseUrl async {
    await _loadStagingPreference();

    if (_useStagingEndpoint == true) {
      // Staging
      return "https://hackathonwriteright.myaddr.tools/files";
    } else {
      // Production
      return "https://writeright-1.eastasia.cloudapp.azure.com";
    }
  }

  static const int timeoutDuration = 120; // in seconds

  // Load staging preference from SharedPreferences
  static Future<void> _loadStagingPreference() async {
    if (_useStagingEndpoint != null) return; // Already loaded

    try {
      final prefs = await SharedPreferences.getInstance();
      _useStagingEndpoint = prefs.getBool('useStagingEndpoint') ?? false;
    } catch (e) {
      _useStagingEndpoint = false; // Default to production
    }
  }

  // Clear cache to force reload (useful when settings change)
  static void clearCache() {
    _useStagingEndpoint = null;
  }


  // Build information - populated during build time
  static const String buildCommitHash = String.fromEnvironment(
    'BUILD_COMMIT_HASH',
    defaultValue: 'unknown',
  );
  static const String buildTimestamp = String.fromEnvironment(
    'BUILD_TIMESTAMP',
    defaultValue: 'unknown',
  );
  static const String buildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: 'unknown',
  );
  static const String buildBranch = String.fromEnvironment(
    'BUILD_BRANCH',
    defaultValue: 'unknown',
  );

  // Build info getter for easy access
  static String get buildInfo =>
      'Build: $buildCommitHash ($buildBranch) - $buildTimestamp';
  static String get shortCommitHash => buildCommitHash.length > 7
      ? buildCommitHash.substring(0, 7)
      : buildCommitHash;

  // // UI-related constants
  // static const double defaultPadding = 16.0;
  // static const String appName = "WriteRight Learner";

  // // Error messages
  // static const String networkError =
  //     "Unable to connect to the network. Please try again later.";
  // static const String unknownError = "An unknown error occurred.";
}
