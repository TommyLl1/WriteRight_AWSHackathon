// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import '../cards/profile_card.dart';
// import '../cards/navigator_widget.dart';
// import '../profile_page/profile_page.dart';
// import '../utils/common_image_cache.dart';
// import '../utils/logger.dart';
// import '../utils/init_all_stores.dart';
// import '../backend/task_store.dart';
// import '../backend/models/task.dart';
// import '../backend/user_info_store.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   bool _isLoading = true;
//   List<Task> _tasks = [];
//   TaskStore? _taskStore;
//   UserInfoStore? _userStatusStore;

//   @override
//   void initState() {
//     super.initState();
//     _initStoresAndWidgets();
//   }

//   Future<void> _initStoresAndWidgets() async {
//     await initAllStores();
//     final getIt = GetIt.instance;
//     _taskStore = getIt<TaskStore>();
//     _userStatusStore = getIt<UserInfoStore>();
//     _taskStore!.addListener(_onTaskStoreChanged);
//     _userStatusStore!.addListener(_onUserStatusChanged);
//     await _initializeWidgets();
//   }

//   @override
//   void dispose() {
//     _taskStore?.removeListener(_onTaskStoreChanged);
//     _userStatusStore?.removeListener(_onUserStatusChanged);
//     super.dispose();
//   }

//   void _onTaskStoreChanged() {
//     setState(() {
//       _tasks = _taskStore!.tasks;
//     });
//   }

//   void _onUserStatusChanged() {
//     setState(() {});
//   }

//   Future<void> _initializeWidgets() async {
//     // Initialize the common image cache
//     await CommonImageCache.initialize();

//     // Start all API calls in parallel but don't block UI on them
//     final futures = <Future<void>>[];

//     // Load cached user status first (synchronous, fast)
//     await _userStatusStore!.loadFromCache();
//     _tasks = _taskStore?.tasks ?? [];

//     // Then start background API calls
//     final fetchTasksFuture = _taskStore?.fetchTasks();
//     if (fetchTasksFuture != null) {
//       futures.add(fetchTasksFuture.catchError((e) {
//         AppLogger.error('Failed to fetch tasks: $e');
//       }));
//     }

//     futures.add(_userStatusStore!.fetchAndUpdate().catchError((e) {
//       AppLogger.error('Failed to fetch user status: $e');
//     }));

//     // Set loading to false immediately so UI can render
//     if (mounted) {
//       setState(() {
//         _isLoading = false;
//       });
//     }

//     // Continue API calls in background
//     Future.wait(futures).then((_) {
//       AppLogger.debug('Background API calls completed');
//     }).catchError((e) {
//       AppLogger.error('Some background API calls failed: $e');
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//     // Use UserInfoStore for all user info
//     final userStore = _userStatusStore!;
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Cached Background
//           CommonImageCache().getBackgroundWidget(),

//           // Content
//           SafeArea(
//             child: Column(
//               children: [
//                 const SizedBox(height: 16),
//                 // Profile Card
//                 ProfileCard(
//                   level: userStore.level,
//                   xpProgress: userStore.xpProgress,
//                   tasks: _tasks,
//                   now: now,
//                 ),
//                 const SizedBox(height: 20),

//                 // Character Image and Name
//                 Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       CommonImageCache().getCharacterWidget(),
//                       const SizedBox(height: 8),
//                       const Text(
//                         '海豚威威',
//                         style: TextStyle(
//                             fontSize: 24, fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // Bottom Menu
//                 const NavigatorCard(),
//               ],
//             ),
//           ),

//           // Menu Button
//           Positioned(
//             top: 16,
//             right: 16,
//             child: SafeArea(
//               child: IconButton(
//                 icon: const Icon(Icons.menu, color: Colors.white, size: 32),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => const ProfilePage()),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
