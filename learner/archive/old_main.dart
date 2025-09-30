// import 'package:flutter/material.dart';
// import 'package:writeright/exercise_page.dart';
// import 'login_page.dart'; // Jump to home page for debugging
// import 'home_page.dart';
// import 'utils/common_image_cache.dart';
// import 'utils/logger.dart';
// import 'backend/services/dependencies.dart';
// import 'game/question_generator.dart';

// void main() async {
//   // Ensure Flutter is initialized
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize the logger first
//   AppLogger.initialize();
//   AppLogger.info('WriteRight app starting...');

//   // Initialize the common image cache system
//   await CommonImageCache.initialize();

//   // // Initialize dependencies
//   await setupDependencies();

//   AppLogger.info('All dependencies initialized successfully');
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Login App',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const HomePage(),
//       // home: const LoginPage(), // Uncomment to use LoginPage
//       // home: ExercisePage(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
