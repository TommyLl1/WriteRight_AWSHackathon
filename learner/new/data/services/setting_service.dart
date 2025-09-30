import 'package:writeright/new/data/api_service.dart';
import 'package:writeright/new/utils/logger.dart';

class SettingService {
  final ApiService _apiService;
  SettingService(this._apiService);

  // Load settings from the API
  Future<Map<String, dynamic>?> loadSettings() async {
    try {
      final response = await _apiService.getUserSettings();
      if (response.statusCode == 200 && response.data != null) {
        AppLogger.debug('SettingService: Loaded settings from API');
        return Map<String, dynamic>.from(response.data['settings'] ?? {});
      } else {
        AppLogger.warning(
            'SettingService: Failed to load settings: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.error('SettingService: Error loading settings: $e');
      return null;
    }
  }

  // Save settings to the API
  Future<bool> saveSettings({
    required String? language,
    required String? theme,
    required Map<String, dynamic>? settings,
  }) async {
    try {
      final response = await _apiService.updateUserSettings(
        language: language,
        theme: theme,
        settings: settings,
      );
      if (response.statusCode == 200) {
        AppLogger.debug('SettingService: Settings saved successfully');
        return true;
      } else {
        AppLogger.error(
            'SettingService: Failed to save settings: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      AppLogger.error('SettingService: Error saving settings: $e');
      return false;
    }
  }
}