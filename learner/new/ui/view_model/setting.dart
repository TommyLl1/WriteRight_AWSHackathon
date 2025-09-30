import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:writeright/new/data/services/setting_service.dart';
import 'package:writeright/new/utils/constants.dart';
import 'package:writeright/new/utils/endpoint_manager.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingService _settingsService;

  // State variables
  Map<String, dynamic>? _settings;
  String? _language;
  String? _theme;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _dirty = false;
  bool _isInitialized = false;

  // Local-only settings (not synced to backend)
  bool _useStagingEndpoint = false;

  // Getters for UI access
  Map<String, dynamic>? get settings => _settings;
  String? get language => _language;
  String? get theme => _theme;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _dirty;
  bool get isInitialized => _isInitialized;

  // Local-only settings getters
  bool get useStagingEndpoint => _useStagingEndpoint;

  // Dictionary settings getter with auto-initialization
  bool get showWrongCountBadge {
    _ensureInitialized();
    return _settings?['dictionary']?['showWrongCountBadge'] ?? true;
  }

  SettingsViewModel(this._settingsService);

  // Initialize and load settings
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent multiple initializations

    _isLoading = true;
    notifyListeners();

    // Load local settings first
    await _loadLocalSettings();

    final loadedSettings = await _settingsService.loadSettings();

    if (loadedSettings != null) {
      _settings = loadedSettings;
      _language = loadedSettings['language'] ?? 'zh-hk';
      _theme = loadedSettings['theme'] ?? 'light';
    } else {
      _initializeDefaultSettings();
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  // Initialize default settings
  void _initializeDefaultSettings() {
    _settings = {
      'dictionary': {'showWrongCountBadge': true},
    };
    _language = 'zh-hk';
    _theme = 'light';
  }

  // Update language
  Future<void> updateLanguage(String language) async {
    if (_language == language) return;

    _language = language;
    _dirty = true;
    notifyListeners();
  }

  // Update theme
  Future<void> updateTheme(String theme) async {
    if (_theme == theme) return;

    _theme = theme;
    _dirty = true;
    notifyListeners();
  }

  // Update dictionary settings
  Future<void> updateDictionarySetting(String key, dynamic value) async {
    _settings ??= {};
    _settings!['dictionary'] ??= {};

    if (_settings!['dictionary'][key] != value) {
      _settings!['dictionary'][key] = value;
      _dirty = true;
      notifyListeners();
    }
  }

  // Update staging endpoint setting (local only)
  Future<void> updateStagingEndpoint(bool useStagingEndpoint) async {
    if (_useStagingEndpoint == useStagingEndpoint) return;

    _useStagingEndpoint = useStagingEndpoint;
    await _saveLocalSettings();

    // Clear the constants cache to force reload with new setting
    AppConstants.clearCache();

    // Try to refresh network configuration
    try {
      final prefs = await SharedPreferences.getInstance();
      await EndpointConfigurationManager.instance.refreshDioConfiguration(
        prefs,
      );
    } catch (e) {
      // Handle error gracefully - user should restart app for full effect
    }

    notifyListeners();
  }

  // Save settings
  Future<void> saveSettings() async {
    if (!_dirty) return;

    _isSaving = true;
    notifyListeners();

    final success = await _settingsService.saveSettings(
      language: _language,
      theme: _theme,
      settings: _settings,
    );

    if (success) {
      _dirty = false;
    }

    _isSaving = false;
    notifyListeners();
  }

  // Refresh settings from the API
  Future<void> refresh() async {
    await initialize();
  }

  // Discard unsaved changes
  void discardChanges() {
    _dirty = false;
    notifyListeners();
  }

  // Ensure the ViewModel is initialized (auto-initialization)
  void _ensureInitialized() {
    if (!_isInitialized && !_isLoading) {
      _isInitialized = true;
      initialize(); // Call async initialization
    }
  }

  // Load local settings from SharedPreferences
  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useStagingEndpoint = prefs.getBool('useStagingEndpoint') ?? false;
    } catch (e) {
      // If there's an error loading, use default values
      _useStagingEndpoint = false;
    }
  }

  // Save local settings to SharedPreferences
  Future<void> _saveLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('useStagingEndpoint', _useStagingEndpoint);
    } catch (e) {
      // Handle error silently for now
    }
  }
}
