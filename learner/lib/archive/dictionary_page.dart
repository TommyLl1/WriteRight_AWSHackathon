// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../cards/wrong_character_card.dart';
// import '../backend/models/wrong_character.dart';
// import '../backend/factories/wrong_character_service_factory.dart';
// import '../backend/services/wrong_character_service.dart';
// import 'dart:math';
// import '../utils/logger.dart';

// class DictionaryPage extends StatefulWidget {
//   const DictionaryPage({super.key});

//   @override
//   _DictionaryPageState createState() => _DictionaryPageState();
// }

// class _DictionaryPageState extends State<DictionaryPage> {
//   WrongCharacterService? _characterService;
//   final TextEditingController _searchController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final FocusNode _searchFocusNode = FocusNode();

//   List<WrongCharacter> _filteredCharacters = [];
//   bool _isLoading = true;
//   bool _isSearching = false;
//   bool _isLoadingMore = false;
//   bool _hasLoadedAll = false;
//   Timer? _debounceTimer;
//   String _currentQuery = '';
//   int _currentPage = 1;
//   int _totalCount = 0;
//   bool _hasMoreData = true;
//   static const int _pageSize = 100; // Increased to maximum allowed
//   static const Duration _debounceDuration = Duration(milliseconds: 500);
//   int? _apiTotalCount; // Store API count fetched once

//   @override
//   void initState() {
//     super.initState();
//     _initializeService();
//     _searchController.addListener(_onSearchChanged);
//     _scrollController.addListener(_onScroll);
//   }

//   Future<void> _initializeService() async {
//     try {
//       _characterService = await WrongCharacterServiceFactory.getAsync();
//       _fetchTotalCount();
//       _loadInitialCharacters();
//     } catch (e) {
//       if (mounted) {
//         _showErrorSnackBar('初始化服務時發生錯誤');
//       }
//     }
//   }

//   Future<void> _fetchTotalCount() async {
//     try {
//       if (_characterService == null) return;
//       final count = await _characterService!.getTotalCount();
//       setState(() {
//         _apiTotalCount = count;
//       });
//     } catch (e) {
//       AppLogger.error('Error fetching total count: $e');
//       // Optionally show error or ignore
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     _scrollController.removeListener(_onScroll);
//     _scrollController.dispose();
//     _searchFocusNode.dispose();
//     _debounceTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _loadInitialCharacters() async {
//     if (_characterService == null) return;

//     setState(() {
//       _isLoading = true;
//       _currentPage = 1;
//     });

//     try {
//       final response = await _characterService!.getAllCharacters(
//         page: _currentPage,
//         pageSize: _pageSize,
//       );
//       setState(() {
//         _filteredCharacters = response.items;
//         // Use the max of API count and loaded count
//         _totalCount = _apiTotalCount != null
//             ? (max(_apiTotalCount!, response.count))
//             : response.count;
//         _hasMoreData = response.items.length >= _pageSize;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       _showErrorSnackBar('載入字詞時發生錯誤');
//     }
//   }

//   void _onSearchChanged() {
//     final query = _searchController.text.trim();

//     // Cancel previous timer
//     _debounceTimer?.cancel();

//     // Don't debounce if query is empty (immediate clear)
//     if (query.isEmpty) {
//       // Schedule after frame to avoid blocking keyboard animation
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           _performSearch('');
//         }
//       });
//       return;
//     }

//     // Set up new timer for debounced search with frame scheduling
//     _debounceTimer = Timer(_debounceDuration, () {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted && _searchFocusNode.hasFocus) {
//           _performSearch(query);
//         }
//       });
//     });
//   }

//   Future<void> _performSearch(String query) async {
//     if (_currentQuery == query || !mounted || _characterService == null)
//       return; // Add mounted and service check

//     _currentQuery = query;

//     // Use microtask to prevent blocking keyboard animations
//     await Future.microtask(() async {
//       if (!mounted) return; // Additional mounted check

//       setState(() {
//         _isSearching = true;
//         _currentPage = 1; // Reset to first page for new search
//         _hasLoadedAll = false; // Reset load all state
//       });

//       try {
//         final results = await _characterService!.searchCharacters(
//           query,
//           page: _currentPage,
//           pageSize: _pageSize,
//         );

//         // Check if this is still the current query and widget is mounted
//         if (_currentQuery == query && mounted) {
//           await Future.microtask(() {
//             if (mounted) {
//               setState(() {
//                 _filteredCharacters =
//                     results.items; // Replace instead of append for new search
//                 _totalCount = results.count;
//                 _hasMoreData = results.items.length >= _pageSize;
//                 _isSearching = false;
//               });
//             }
//           });
//         }
//       } catch (e) {
//         if (_currentQuery == query && mounted) {
//           setState(() {
//             _isSearching = false;
//           });
//           _showErrorSnackBar('搜尋時發生錯誤');
//         }
//       }
//     });
//   }

//   void _showErrorSnackBar(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red[700],
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   Future<void> _handleRefresh() async {
//     setState(() {
//       _currentPage = 1;
//       _hasLoadedAll = false;
//     });
//     await _loadInitialCharacters();
//     _searchController.clear();
//   }

//   void _onScroll() {
//     // Unfocus search field when scrolling to prevent input conflicts
//     if (_searchFocusNode.hasFocus) {
//       _searchFocusNode.unfocus();
//     }

//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 200) {
//       // Load more when near bottom (200px threshold)
//       if (_hasMoreData &&
//           !_isLoadingMore &&
//           !_isLoading &&
//           !_isSearching &&
//           !_hasLoadedAll) {
//         _loadMoreCharacters();
//       }
//     }
//   }

//   Future<void> _loadMoreCharacters() async {
//     if (_isLoadingMore || _characterService == null) return;

//     setState(() {
//       _isLoadingMore = true;
//     });

//     try {
//       final nextPage = _currentPage + 1;

//       WrongCharacterResponse response;
//       if (_currentQuery.isEmpty) {
//         response = await _characterService!.getAllCharacters(
//           page: nextPage,
//           pageSize: _pageSize,
//         );
//       } else {
//         response = await _characterService!.searchCharacters(
//           _currentQuery,
//           page: nextPage,
//           pageSize: _pageSize,
//         );
//       }

//       setState(() {
//         _currentPage = nextPage;
//         _filteredCharacters.addAll(response.items); // Append instead of replace
//         _hasMoreData = response.items.length >= _pageSize;
//         _isLoadingMore = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoadingMore = false;
//       });
//       _showErrorSnackBar('載入更多資料時發生錯誤');
//     }
//   }

//   Future<void> _loadAllCharacters() async {
//     if (_hasLoadedAll || _characterService == null) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final allCharacters = await _characterService!.loadAllCharacters();

//       setState(() {
//         _filteredCharacters = allCharacters;
//         _totalCount = allCharacters.length;
//         _hasMoreData = false;
//         _hasLoadedAll = true;
//         _isLoading = false;
//       });

//       _showSnackBar('已載入全部 ${allCharacters.length} 個字詞');
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       _showErrorSnackBar('載入全部資料時發生錯誤');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF062E47),
//       resizeToAvoidBottomInset: true, // Optimize keyboard animations
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top bar with back and hidden menu
//             Padding(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 8.0,
//                 vertical: 12.0,
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: Colors.white),
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                   ),
//                   const Text(
//                     '錯字庫',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   PopupMenuButton<String>(
//                     icon: const Icon(Icons.more_vert, color: Colors.white),
//                     color: const Color(0xFF1E4A5F),
//                     onSelected: (value) {
//                       switch (value) {
//                         case 'refresh':
//                           _handleRefresh();
//                           break;
//                         case 'load_all':
//                           _loadAllCharacters();
//                           break;
//                       }
//                     },
//                     itemBuilder: (context) => [
//                       const PopupMenuItem(
//                         value: 'refresh',
//                         child: Row(
//                           children: [
//                             Icon(Icons.refresh, color: Colors.white, size: 20),
//                             SizedBox(width: 8),
//                             Text('重新整理', style: TextStyle(color: Colors.white)),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'load_all',
//                         child: Row(
//                           children: [
//                             Icon(Icons.download, color: Colors.white, size: 20),
//                             SizedBox(width: 8),
//                             Text('載入全部', style: TextStyle(color: Colors.white)),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // Search bar
//             Padding(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 12.0,
//                 vertical: 8.0,
//               ),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(30),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: TextField(
//                   controller: _searchController,
//                   focusNode: _searchFocusNode,
//                   textAlignVertical: TextAlignVertical.center,
//                   textInputAction: TextInputAction.search,
//                   onSubmitted: (value) {
//                     // Handle search submission
//                     if (value.trim().isNotEmpty) {
//                       _performSearch(value.trim());
//                     }
//                     _searchFocusNode.unfocus();
//                   },
//                   decoration: InputDecoration(
//                     hintText: '搜尋錯別字、讀音或意思...',
//                     hintStyle: TextStyle(color: Colors.grey[600]),
//                     border: InputBorder.none,
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 15,
//                     ),
//                     suffixIcon: _isSearching
//                         ? const Padding(
//                             padding: EdgeInsets.all(12.0),
//                             child: SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   Color(0xFF062E47),
//                                 ),
//                               ),
//                             ),
//                           )
//                         : _searchController.text.isNotEmpty
//                             ? IconButton(
//                                 icon: const Icon(Icons.clear),
//                                 onPressed: () {
//                                   _searchController.clear();
//                                   _searchFocusNode.unfocus();
//                                 },
//                               )
//                             : const Icon(
//                                 Icons.search,
//                                 color: Colors.grey,
//                               ),
//                     isDense: true,
//                   ),
//                 ),
//               ),
//             ),

//             // Character count and loading indicator
//             if (_isLoading)
//               const Expanded(
//                 child: Center(
//                   child: CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 ),
//               )
//             else ...[
//               // Results count
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Row(
//                   children: [
//                     Text(
//                       '共找到 $_totalCount 個字詞',
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 14,
//                       ),
//                     ),
//                     if (_hasLoadedAll) ...[
//                       const SizedBox(width: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 6, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: Colors.green.withValues(alpha: 0.7),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: const Text(
//                           '已全部載入',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ] else if (_hasMoreData &&
//                         _filteredCharacters.isNotEmpty) ...[
//                       const SizedBox(width: 8),
//                       Text(
//                         '(已載入 ${_filteredCharacters.length} 個)',
//                         style: const TextStyle(
//                           color: Colors.white54,
//                           fontSize: 12,
//                         ),
//                       ),
//                       const SizedBox(width: 4),
//                       const Icon(
//                         Icons.keyboard_arrow_down,
//                         color: Colors.white54,
//                         size: 16,
//                       ),
//                     ] else if (_filteredCharacters.isNotEmpty) ...[
//                       const SizedBox(width: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 6, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.withValues(alpha: 0.7),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: const Text(
//                           '全部顯示',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 8),

//               // Character list
//               Expanded(
//                 child: _filteredCharacters.isEmpty
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.search_off,
//                               size: 64,
//                               color: Colors.white38,
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               _searchController.text.isNotEmpty
//                                   ? '找不到符合的結果'
//                                   : '暫無字詞資料',
//                               style: const TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: 18,
//                               ),
//                             ),
//                             if (_searchController.text.isNotEmpty) ...[
//                               const SizedBox(height: 8),
//                               Text(
//                                 '請嘗試其他關鍵字',
//                                 style: const TextStyle(
//                                   color: Colors.white54,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       )
//                     : RefreshIndicator(
//                         onRefresh: _handleRefresh,
//                         color: const Color(0xFF062E47),
//                         child: ListView.builder(
//                           controller: _scrollController,
//                           physics: const AlwaysScrollableScrollPhysics(),
//                           itemCount: _filteredCharacters.length +
//                               (_isLoadingMore ? 1 : 0),
//                           itemBuilder: (context, index) {
//                             // Show loading indicator at bottom
//                             if (index == _filteredCharacters.length) {
//                               return Container(
//                                 padding: const EdgeInsets.all(16),
//                                 alignment: Alignment.center,
//                                 child: const CircularProgressIndicator(
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                       Colors.white),
//                                 ),
//                               );
//                             }

//                             final character = _filteredCharacters[index];
//                             return WrongCharacterCard(
//                               wrongCharacter: character,
//                               onEdit: () {
//                                 // TODO: Implement copy functionality
//                                 _showSnackBar('臨摹功能即將推出');
//                               },
//                               // Removed onPlaySound callback - handled internally by card
//                             );
//                           },
//                         ),
//                       ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSnackBar(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           behavior: SnackBarBehavior.floating,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }
// }
