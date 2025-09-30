// import 'package:get_it/get_it.dart';
// import 'package:dio/dio.dart';
// import '../../utils/dio.dart';
// import '../../utils/logger.dart';
// import '../../utils/api_service.dart';
// import 'game_service.dart';
// import 'auth_service.dart';
// import 'wrong_character_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// final getIt = GetIt.instance;

// Future<void> setupDependencies() async {
//   // Register SharedPreferences (asynchronous initialization)
//   final sharedPreferences = await SharedPreferences.getInstance();
//   getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

//   // Register Dio
//   getIt.registerLazySingleton<Dio>(
//       () => DioProvider.createDio(getIt<SharedPreferences>()));

//   // Register ApiService (async creation)
//   getIt.registerLazySingletonAsync<ApiService>(
//       () async => ApiService.create(getIt<SharedPreferences>()));

//   // Register services that depend on ApiService
//   getIt.registerLazySingleton<AuthService>(
//       () => AuthService(getIt<SharedPreferences>(), getIt<Dio>()));

//   // Register WrongCharacterService after ApiService is ready
//   getIt.registerLazySingletonAsync<WrongCharacterService>(() async {
//     final apiService = await getIt.getAsync<ApiService>();
//     final service = WrongCharacterService();
//     service.initialize(apiService);
//     return service;
//   });
//   getIt.registerLazySingletonAsync<GameService>(() async {
//     final apiService = await getIt.getAsync<ApiService>();
//     final service = GameService();
//     service.initialize(apiService);
//     return service;
//   });

//   // Ensure all async services are ready
//   await getIt.allReady();
// }

// // Example usage of the service
// void testUserLogin() async {
//   final authService = getIt<AuthService>();
//   try {
//     await authService.login(
//       email: 'test@email.com',
//       password: 'password123',
//     );
//     AppLogger.info('Login successful');
//   } catch (e) {
//     AppLogger.error('Login failed', e);
//   }
// }

// void main() async {
//   // Initialize dependencies
//   await setupDependencies();

//   // Example usage of the AuthService
//   testUserLogin();
// }
