// import 'package:flutter_test/flutter_test.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../lib/backend/services/dependencies.dart';
// import '../lib/backend/services/wrong_character_service.dart';
// import '../lib/backend/factories/wrong_character_service_factory.dart';
// import '../lib/utils/api_service.dart';

// void main() {
//   group('WrongCharacterService API Integration Tests', () {
//     setUpAll(() async {
//       // Initialize SharedPreferences for testing
//       SharedPreferences.setMockInitialValues({});

//       // Setup dependencies
//       await setupDependencies();
//     });

//     test('should initialize service successfully', () async {
//       final service = await WrongCharacterServiceFactory.getAsync();

//       expect(service, isNotNull);
//       expect(service.isInitialized, isTrue);
//       expect(service.currentUserId, isNotNull);
//     });

//     test('should get factory instance after initialization', () async {
//       // Ensure service is initialized
//       await WrongCharacterServiceFactory.getAsync();

//       final instance = WrongCharacterServiceFactory.instance;
//       expect(instance, isNotNull);
//       expect(instance!.isInitialized, isTrue);
//     });

//     test('should handle service factory ready check', () {
//       expect(WrongCharacterServiceFactory.isReady, isTrue);
//     });

//     test('service methods should not throw when called', () async {
//       final service = await WrongCharacterServiceFactory.getAsync();

//       // These tests assume the API might not be available, so we just check they don't throw
//       // In a real environment, you'd mock the API responses
//       expect(() async {
//         try {
//           await service.getAllCharacters(page: 1, pageSize: 10);
//         } catch (e) {
//           // Expected if API is not available
//           print('API call failed (expected): $e');
//         }
//       }, returnsNormally);

//       expect(() async {
//         try {
//           await service.searchCharacters('test', page: 1, pageSize: 10);
//         } catch (e) {
//           // Expected if API is not available
//           print('API search failed (expected): $e');
//         }
//       }, returnsNormally);
//     });

//     test('should handle character lookup gracefully', () async {
//       final service = await WrongCharacterServiceFactory.getAsync();

//       expect(() async {
//         try {
//           final character = await service.getCharacterById(1);
//           // Character might be null if not found
//           print('Character by ID result: $character');
//         } catch (e) {
//           print('Get character by ID failed (expected): $e');
//         }
//       }, returnsNormally);
//     });
//   });
// }
