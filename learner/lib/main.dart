// packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

// Local imports
import 'package:writeright/new/utils/dio.dart';
import 'package:writeright/new/data/api_service.dart';
import 'package:writeright/new/ui/view_model/exports.dart';
import 'package:writeright/new/data/services/exports.dart';

// Router
import 'package:writeright/new/routers/router.dart';

import 'package:writeright/new/utils/endpoint_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Create Dio instance
  final dio = await DioProvider.createDio(sharedPreferences);

  // Initialize endpoint manager
  EndpointConfigurationManager.instance.initialize(dio);

  // Initialize API service
  final apiPerv = ApiService(dio, sharedPreferences);

  // Initialize the common image cache system
  await CommonImageCache.initialize();
  final commonImageCache = CommonImageCache();

  runApp(
    MultiProvider(
      providers: [
        // Base components
        Provider<SharedPreferences>.value(
          value: sharedPreferences,
        ), // Provide SharedPreferences
        Provider<Dio>.value(value: dio), // Provide Dio instance
        Provider<ApiService>.value(value: apiPerv), // Provide ApiService
        Provider<CommonImageCache>.value(
          value: commonImageCache,
        ), // Provide CommonImageCache
        // Repositories
        Provider<UserRepository>(
          create: (context) => UserRepository(apiPerv),
          lazy: true,
        ),
        Provider<TaskRepository>(
          create: (context) => TaskRepository(apiPerv),
          lazy: true,
        ),
        Provider<GameService>(
          create: (context) => GameService(apiPerv, sharedPreferences),
          lazy: true,
        ),
        Provider<WrongCharacterService>(
          create: (context) =>
              WrongCharacterService(context.read<ApiService>()),
          lazy: true,
        ),
        Provider<AuthService>(
          create: (context) => AuthService(sharedPreferences, dio),
          lazy: true,
        ),
        Provider<PermissionService>(
          create: (context) => PermissionService(),
          lazy: true,
        ),
        Provider<SettingService>(
          create: (context) => SettingService(apiPerv),
          lazy: true,
        ),

        // ViewModels
        /// Global ViewModels that need to persist across routes
        ChangeNotifierProvider<SettingsViewModel>(
          create: (context) =>
              SettingsViewModel(context.read<SettingService>()),
          lazy: true,
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(
            taskRepository: context.read<TaskRepository>(),
            wrongCharacterService: context.read<WrongCharacterService>(),
            userRepository: context.read<UserRepository>(),
            sharedPreferences: sharedPreferences,
            imageCache: commonImageCache,
          ),
          lazy: false,
        ),
        // ChangeNotifierProvider<ExerciseViewModel>(
        //   create: (context) => ExerciseViewModel(
        //     imageCache: commonImageCache,
        //   ),
        //   lazy: true,
        // ),
        // ChangeNotifierProvider<GameViewModel>(
        //   create: (context) => GameViewModel(
        //     gameService: GameService(apiPerv),
        //   ),
        //   lazy: true,
        // ),
        // ChangeNotifierProvider<LoginViewModel>(
        //   create: (context) => LoginViewModel(
        //     AuthService(sharedPreferences, dio),
        //   ),
        //   lazy: true,
        // ),
        // ChangeNotifierProvider<WrongWordsViewModel>(
        //   create: (context) => WrongWordsViewModel(
        //     WrongCharacterService(ApiService(dio, sharedPreferences)),
        //   ),
        //   lazy: true,
        // ),
      ],
      child: App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    // Initialize the router
    return MaterialApp.router(routerConfig: AppRouter.router);
  }
}
