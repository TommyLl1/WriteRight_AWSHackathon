import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:writeright/new/data/models/wrong_character.dart';
import 'package:writeright/new/data/services/wrong_character.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/data/services/setting_service.dart';
import 'package:writeright/new/ui/view_model/setting.dart';

class DictionaryViewModel extends ChangeNotifier {
  final WrongCharacterService _characterService;
  final SettingService _settingService;

  DictionaryViewModel(this._characterService, this._settingService);

  // State variables
  List<WrongCharacter> _filteredCharacters = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _hasLoadedAll = false;
  String _currentQuery = '';
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasMoreData = true;
  static const int _pageSize = 100;
  int? _apiTotalCount;

  // Getters for the view
  List<WrongCharacter> get filteredCharacters => _filteredCharacters;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasLoadedAll => _hasLoadedAll;
  int get totalCount => _totalCount;
  bool get hasMoreData => _hasMoreData;

  /// ShowWrongCountBadge setting
  late bool _showWrongCountBadge;
  bool get showWrongCountBadge => _showWrongCountBadge;

  // Initialize the service and load initial data
  Future<void> initialize(
      [SettingsViewModel? existingSettingsViewModel]) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _fetchTotalCount();
      await _loadInitialCharacters();

      /// Load settings efficiently - use global SettingsViewModel when available
      if (existingSettingsViewModel != null) {
        // Check if settings are already initialized
        if (existingSettingsViewModel.isInitialized &&
            !existingSettingsViewModel.isLoading) {
          // Use existing settings from global SettingsViewModel
          _showWrongCountBadge = existingSettingsViewModel.showWrongCountBadge;
          AppLogger.debug(
              'DictionaryViewModel: Using settings from global SettingsViewModel');
        } else {
          // SettingsViewModel exists but may need initialization
          if (!existingSettingsViewModel.isInitialized) {
            AppLogger.debug(
                'DictionaryViewModel: Initializing global SettingsViewModel...');
            await existingSettingsViewModel.initialize();
          } else {
            // SettingsViewModel is currently loading, wait for it
            AppLogger.debug(
                'DictionaryViewModel: Global SettingsViewModel is loading, waiting...');
            await _waitForSettingsToLoad(existingSettingsViewModel);
          }
          _showWrongCountBadge = existingSettingsViewModel.showWrongCountBadge;
          AppLogger.debug(
              'DictionaryViewModel: Settings loaded from global SettingsViewModel');
        }
      } else {
        // No global SettingsViewModel available, load directly from API
        final settingResponse = await _settingService.loadSettings();
        _showWrongCountBadge =
            settingResponse?['dictionary']?['showWrongCountBadge'] ?? true;
        AppLogger.debug('DictionaryViewModel: Loaded fresh settings from API');
      }
    } catch (e) {
      AppLogger.error('Error initializing DictionaryViewModel: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch total count from the API
  Future<void> _fetchTotalCount() async {
    try {
      final count = await _characterService.getTotalCount();
      _apiTotalCount = count;
    } catch (e) {
      AppLogger.error('Error fetching total count: $e');
    }
  }

  // Load initial characters
  Future<void> _loadInitialCharacters() async {
    try {
      final response = await _characterService.getAllCharacters(
        page: _currentPage,
        pageSize: _pageSize,
      );
      _filteredCharacters = response.items;
      _totalCount = _apiTotalCount != null
          ? max(_apiTotalCount!, response.count)
          : response.count;
      _hasMoreData = response.items.length >= _pageSize;
    } catch (e) {
      AppLogger.error('Error loading initial characters: $e');
    }
  }

  // Perform search with debounce
  Future<void> performSearch(String query) async {
    if (_currentQuery == query) return; // Skip if query hasn't changed

    _currentQuery = query;
    _isSearching = true;
    _currentPage = 1;
    _hasLoadedAll = false;
    notifyListeners();

    try {
      final results = await _characterService.searchCharacters(
        query,
        page: _currentPage,
        pageSize: _pageSize,
      );
      _filteredCharacters = results.items;
      _totalCount = results.count;
      _hasMoreData = results.items.length >= _pageSize;
    } catch (e) {
      AppLogger.error('Error performing search: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Load more characters (pagination)
  Future<void> loadMoreCharacters() async {
    if (_isLoadingMore || !_hasMoreData) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = _currentQuery.isEmpty
          ? await _characterService.getAllCharacters(
              page: nextPage,
              pageSize: _pageSize,
            )
          : await _characterService.searchCharacters(
              _currentQuery,
              page: nextPage,
              pageSize: _pageSize,
            );

      _currentPage = nextPage;
      _filteredCharacters.addAll(response.items);
      _hasMoreData = response.items.length >= _pageSize;
    } catch (e) {
      AppLogger.error('Error loading more characters: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Refresh the list
  Future<void> refresh() async {
    _currentPage = 1;
    _hasLoadedAll = false;
    _currentQuery = '';
    await _loadInitialCharacters();
    notifyListeners();
  }

  // Load all characters
  Future<void> loadAllCharacters() async {
    if (_hasLoadedAll) return;

    _isLoading = true;
    notifyListeners();

    try {
      final allCharacters = await _characterService.loadAllCharacters();
      _filteredCharacters = allCharacters;
      _totalCount = allCharacters.length;
      _hasMoreData = false;
      _hasLoadedAll = true;
    } catch (e) {
      AppLogger.error('Error loading all characters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to wait for settings to load
  Future<void> _waitForSettingsToLoad(
      SettingsViewModel settingsViewModel) async {
    // Wait up to 5 seconds for settings to load
    int attempts = 0;
    const maxAttempts = 50; // 50 * 100ms = 5 seconds

    while (settingsViewModel.isLoading && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (settingsViewModel.isLoading) {
      AppLogger.warning(
          'DictionaryViewModel: Timeout waiting for settings to load');
    }
  }
}
