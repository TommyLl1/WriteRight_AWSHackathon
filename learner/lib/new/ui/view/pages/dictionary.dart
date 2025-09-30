import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/ui/view_model/dictionary.dart';
import 'package:writeright/new/ui/view_model/setting.dart';
import 'package:writeright/new/ui/view/widgets/wrong_word_card.dart';
import 'package:writeright/new/utils/logger.dart';

/// Dictionary page that displays wrong characters and handles search functionality.
/// Now uses global SettingsViewModel to efficiently share settings across the app.

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  _DictionaryPageState createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  bool _isSnackBarVisible = false; // Flag to track snack bar visibility

  @override
  void initState() {
    super.initState();
    _initializeViewModel();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  //// INITIALIZATION AND DATA FETCHING ////

  /// Initialize the DictionaryViewModel, using global SettingsViewModel when available
  Future<void> _initializeViewModel() async {
    try {
      final dictionaryViewModel = Provider.of<DictionaryViewModel>(
        context,
        listen: false,
      );

      // Always try to get the global SettingsViewModel first
      SettingsViewModel? settingsViewModel;

      // Check if SettingsViewModel is available in the global context
      try {
        settingsViewModel = context.read<SettingsViewModel>();
        AppLogger.debug(
          'Found global SettingsViewModel, will use cached settings',
        );
      } on ProviderNotFoundException {
        // Fallback: SettingsViewModel not provided globally (shouldn't happen now)
        settingsViewModel = null;
        AppLogger.warning(
          'No global SettingsViewModel found, will load settings from API directly',
        );
      }

      // Initialize the dictionary with optional settings
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dictionaryViewModel.initialize(settingsViewModel);
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('初始化服務時發生錯誤');
      }
    }
  }

  /// Handle search input changes with debouncing
  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Don't debounce if query is empty (immediate clear)
    if (query.isEmpty) {
      // Schedule after frame to avoid blocking keyboard animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _performSearch('');
        }
      });
      return;
    }

    // Set up new timer for debounced search with frame scheduling
    _debounceTimer = Timer(_debounceDuration, () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchFocusNode.hasFocus) {
          _performSearch(query);
        }
      });
    });
  }

  /// Called after the search query changes and validated input.
  Future<void> _performSearch(String query) async {
    final dictionaryViewModel = Provider.of<DictionaryViewModel>(
      context,
      listen: false,
    );
    await dictionaryViewModel.performSearch(query);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRefresh() async {
    final dictionaryViewModel = Provider.of<DictionaryViewModel>(
      context,
      listen: false,
    );

    // Get the global SettingsViewModel for refresh
    SettingsViewModel? settingsViewModel;
    try {
      settingsViewModel = context.read<SettingsViewModel>();
    } on ProviderNotFoundException {
      settingsViewModel = null;
    }

    // Reset search and refresh data with settings
    _searchController.clear();
    await dictionaryViewModel.initialize(settingsViewModel);
  }

  void _onScroll() {
    // Unfocus search field when scrolling to prevent input conflicts
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom (200px threshold)
      final dictionaryViewModel = Provider.of<DictionaryViewModel>(
        context,
        listen: false,
      );
      if (dictionaryViewModel.hasMoreData &&
          !dictionaryViewModel.isLoadingMore &&
          !dictionaryViewModel.isLoading &&
          !dictionaryViewModel.isSearching &&
          !dictionaryViewModel.hasLoadedAll) {
        dictionaryViewModel.loadMoreCharacters();
      }
    }
  }

  Future<void> _loadAllCharacters() async {
    final dictionaryViewModel = Provider.of<DictionaryViewModel>(
      context,
      listen: false,
    );
    await dictionaryViewModel.loadAllCharacters();
    if (mounted) {
      _showSnackBar('已載入全部 ${dictionaryViewModel.totalCount} 個字詞');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DictionaryViewModel>(
      builder: (context, dictionaryViewModel, child) {
        AppLogger.debug(
          "isLoading: ${dictionaryViewModel.isLoading}, "
          "isSearching: ${dictionaryViewModel.isSearching}, "
          "isLoadingMore: ${dictionaryViewModel.isLoadingMore}, "
          "hasLoadedAll: ${dictionaryViewModel.hasLoadedAll}, "
          "totalCount: ${dictionaryViewModel.totalCount}, "
          "filteredCharacters: ${dictionaryViewModel.filteredCharacters.length}",
        );

        return Scaffold(
          backgroundColor: const Color(0xFF062E47),
          resizeToAvoidBottomInset: true, // Optimize keyboard animations
          body: SafeArea(
            child: Column(
              children: [
                // Top bar with back and hidden menu
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/home'),
                      ),
                      const Text(
                        '錯字庫',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      /// Top right menu with refresh and load all options
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        color: const Color(0xFF1E4A5F),
                        onSelected: (value) {
                          switch (value) {
                            case 'refresh':
                              _handleRefresh();
                              break;
                            case 'load_all':
                              _loadAllCharacters();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'refresh',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '重新整理',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'load_all',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.download,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '載入全部',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        // Handle search submission
                        if (value.trim().isNotEmpty) {
                          _performSearch(value.trim());
                        }
                        _searchFocusNode.unfocus();
                      },
                      decoration: InputDecoration(
                        hintText: '搜尋錯別字、讀音或意思...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        suffixIcon: dictionaryViewModel.isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF062E47),
                                    ),
                                  ),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchFocusNode.unfocus();
                                },
                              )
                            : const Icon(Icons.search, color: Colors.grey),
                        isDense: true,
                      ),
                    ),
                  ),
                ),

                // Character count and loading indicator
                if (dictionaryViewModel.isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                else ...[
                  // Results count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text(
                          '共找到 ${dictionaryViewModel.totalCount} 個字詞',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        if (dictionaryViewModel.hasLoadedAll) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '已全部載入',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else if (dictionaryViewModel.hasMoreData &&
                            dictionaryViewModel
                                .filteredCharacters
                                .isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(已載入 ${dictionaryViewModel.filteredCharacters.length} 個)',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ] else if (dictionaryViewModel
                            .filteredCharacters
                            .isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '全部顯示',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Character list
                  Expanded(
                    child: dictionaryViewModel.filteredCharacters.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.white38,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? '找不到符合的結果'
                                      : '暫無字詞資料',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '請嘗試其他關鍵字',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _handleRefresh,
                            color: const Color(0xFF062E47),
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount:
                                  dictionaryViewModel
                                      .filteredCharacters
                                      .length +
                                  (dictionaryViewModel.isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Show loading indicator at bottom
                                if (index ==
                                    dictionaryViewModel
                                        .filteredCharacters
                                        .length) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  );
                                }

                                final character = dictionaryViewModel
                                    .filteredCharacters[index];
                                return WrongCharacterCard(
                                  wrongCharacter: character,
                                  onEdit: () {
                                    // TODO: Implement copy functionality
                                    _showSnackBar('臨摹功能即將推出');
                                  },
                                  onPlaySound: () {
                                    // TODO: Implement sound playing
                                    _showSnackBar(
                                      '正在播放 "${character.character}" 的讀音',
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (_isSnackBarVisible) return; // Prevent showing multiple snack bars

    _isSnackBarVisible = true; // Set the flag
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        onVisible: () {
          // Reset the flag when the snack bar is dismissed
          Future.delayed(const Duration(seconds: 2), () {
            _isSnackBarVisible = false;
          });
        },
      ),
    );
  }
}
