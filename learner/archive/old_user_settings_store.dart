// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import 'api_service.dart';
// import '../utils/logger.dart';

// class UserSettingsStore extends ChangeNotifier {
//   Map<String, dynamic>? _settings;
//   String? _language;
//   String? _theme;
//   bool _isLoading = true;
//   bool _isSaving = false;

//   // Track staged (unsaved) changes
//   Map<String, dynamic>? _stagedSettings;
//   String? _stagedLanguage;
//   String? _stagedTheme;
//   bool _dirty = false;

//   // Getters
//   Map<String, dynamic>? get settings => _settings;
//   String? get language => _language;
//   String? get theme => _theme;
//   bool get isLoading => _isLoading;
//   bool get isSaving => _isSaving;
//   bool get isReady => _settings != null && !_isLoading;

//   bool get hasUnsavedChanges => _dirty;

//   // Dictionary settings getters
//   bool get showWrongCountBadge =>
//       _settings?['dictionary']?['showWrongCountBadge'] ?? true;

//   // Getters for staged values (fall back to saved if not staged)
//   Map<String, dynamic>? get stagedSettings => _stagedSettings ?? _settings;
//   String? get stagedLanguage => _stagedLanguage ?? _language;
//   String? get stagedTheme => _stagedTheme ?? _theme;

//   // Use staged values for UI
//   bool get stagedShowWrongCountBadge =>
//       (_stagedSettings ?? _settings)?['dictionary']?['showWrongCountBadge'] ??
//       true;

//   // Initialize and load settings from API
//   Future<void> initialize() async {
//     await loadFromApi();
//   }

//   // Load settings from API
//   Future<void> loadFromApi() async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       final apiService = await GetIt.instance.getAsync<ApiService>();
//       final response = await apiService.getUserSettings();

//       if (response.statusCode == 200 && response.data != null) {
//         final data = response.data;
//         _language = data['language'];
//         _theme = data['theme'];
//         _settings = Map<String, dynamic>.from(data['settings'] ?? {});

//         AppLogger.debug(
//             'UserSettingsStore: Loaded settings from API: $_settings');
//       } else {
//         AppLogger.warning(
//             'UserSettingsStore: Failed to load settings from API');
//         _initializeDefaultSettings();
//       }
//     } catch (e) {
//       AppLogger.error('UserSettingsStore: Error loading settings: $e');
//       _initializeDefaultSettings();
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Initialize default settings
//   void _initializeDefaultSettings() {
//     _language = 'zh-hk';
//     _theme = 'light';
//     _settings = {
//       'dictionary': {
//         'showWrongCountBadge': true,
//       }
//     };
//     AppLogger.debug('UserSettingsStore: Initialized with default settings');
//   }

//   // Update language setting
//   Future<void> updateLanguage(String language) async {
//     if (_language == language) return;

//     _language = language;
//     notifyListeners();
//     await _saveToApi();
//   }

//   // Update theme setting
//   Future<void> updateTheme(String theme) async {
//     if (_theme == theme) return;

//     _theme = theme;
//     notifyListeners();
//     await _saveToApi();
//   }

//   // Update dictionary settings
//   Future<void> updateDictionarySettings({
//     bool? showWrongCountBadge,
//   }) async {
//     _settings ??= {};

//     if (_settings!['dictionary'] == null) {
//       _settings!['dictionary'] = {};
//     }

//     bool hasChanges = false;

//     if (showWrongCountBadge != null &&
//         _settings!['dictionary']['showWrongCountBadge'] !=
//             showWrongCountBadge) {
//       _settings!['dictionary']['showWrongCountBadge'] = showWrongCountBadge;
//       hasChanges = true;
//     }

//     if (hasChanges) {
//       notifyListeners();
//       await _saveToApi();
//     }
//   }

//   // Update a specific dictionary setting
//   Future<void> updateDictionarySetting(String key, dynamic value) async {
//     _settings ??= {};

//     if (_settings!['dictionary'] == null) {
//       _settings!['dictionary'] = {};
//     }

//     if (_settings!['dictionary'][key] != value) {
//       _settings!['dictionary'][key] = value;
//       notifyListeners();
//       await _saveToApi();
//     }
//   }

//   // Update any custom setting
//   Future<void> updateSetting(String path, dynamic value) async {
//     _settings ??= {};

//     final pathParts = path.split('.');
//     Map<String, dynamic> current = _settings!;

//     // Navigate to the parent of the target key
//     for (int i = 0; i < pathParts.length - 1; i++) {
//       final key = pathParts[i];
//       if (current[key] == null) {
//         current[key] = <String, dynamic>{};
//       }
//       current = current[key];
//     }

//     // Set the value
//     final lastKey = pathParts.last;
//     if (current[lastKey] != value) {
//       current[lastKey] = value;
//       notifyListeners();
//       await _saveToApi();
//     }
//   }

//   // Save settings to API
//   Future<void> _saveToApi() async {
//     if (_isSaving) return; // Prevent concurrent saves

//     try {
//       _isSaving = true;
//       notifyListeners();

//       final apiService = await GetIt.instance.getAsync<ApiService>();

//       final response = await apiService.updateUserSettings(
//         language: _language,
//         theme: _theme,
//         settings: _settings,
//       );

//       if (response.statusCode == 200) {
//         AppLogger.debug('UserSettingsStore: Settings saved successfully');
//       } else {
//         AppLogger.error(
//             'UserSettingsStore: Failed to save settings: ${response.statusCode}');
//       }
//     } catch (e) {
//       AppLogger.error('UserSettingsStore: Error saving settings: $e');
//     } finally {
//       _isSaving = false;
//       notifyListeners();
//     }
//   }

//   // Refresh settings from API
//   Future<void> refresh() async {
//     await loadFromApi();
//   }

//   // Get a setting by path (e.g., "dictionary.showWrongCountBadge")
//   dynamic getSetting(String path, [dynamic defaultValue]) {
//     if (_settings == null) return defaultValue;

//     final pathParts = path.split('.');
//     dynamic current = _settings;

//     for (final part in pathParts) {
//       if (current is Map<String, dynamic> && current.containsKey(part)) {
//         current = current[part];
//       } else {
//         return defaultValue;
//       }
//     }

//     return current ?? defaultValue;
//   }

//   // Setters for staged changes
//   void stageLanguage(String language) {
//     _stagedLanguage = language;
//     _dirty = true;
//     notifyListeners();
//   }

//   void stageTheme(String theme) {
//     _stagedTheme = theme;
//     _dirty = true;
//     notifyListeners();
//   }

//   void stageDictionarySetting(String key, dynamic value) {
//     _stagedSettings ??= Map<String, dynamic>.from(_settings ?? {});
//     _stagedSettings!['dictionary'] ??= {};
//     if (_stagedSettings!['dictionary'][key] != value) {
//       _stagedSettings!['dictionary'][key] = value;
//       _dirty = true;
//       notifyListeners();
//     }
//   }

//   // Save staged changes to API
//   Future<void> save() async {
//     if (!_dirty) return;
//     _language = _stagedLanguage ?? _language;
//     _theme = _stagedTheme ?? _theme;
//     _settings = _stagedSettings ?? _settings;
//     _stagedLanguage = null;
//     _stagedTheme = null;
//     _stagedSettings = null;
//     _dirty = false;
//     notifyListeners();
//     await _saveToApi();
//   }

//   // Discard staged changes
//   void discardChanges() {
//     _stagedLanguage = null;
//     _stagedTheme = null;
//     _stagedSettings = null;
//     _dirty = false;
//     notifyListeners();
//   }
// }
