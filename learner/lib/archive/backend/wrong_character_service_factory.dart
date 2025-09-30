// import 'services/dependencies.dart';


// /// Factory class to provide easy access to WrongCharacterService
// class WrongCharacterServiceFactory {
//   static WrongCharacterService? _cachedService;

//   /// Gets the WrongCharacterService instance
//   /// Returns null if the service is not ready or not initialized
//   static WrongCharacterService? get instance {
//     try {
//       if (_cachedService != null && _cachedService!.isInitialized) {
//         return _cachedService;
//       }

//       if (getIt.isRegistered<WrongCharacterService>()) {
//         final service = getIt.get<WrongCharacterService>();
//         if (service.isInitialized) {
//           _cachedService = service;
//           return service;
//         } else {
//           AppLogger.warning(
//               'WrongCharacterService is registered but not initialized');
//           return null;
//         }
//       } else {
//         AppLogger.warning('WrongCharacterService is not registered');
//         return null;
//       }
//     } catch (e) {
//       AppLogger.error('Error getting WrongCharacterService instance: $e');
//       return null;
//     }
//   }

//   /// Gets the WrongCharacterService instance asynchronously
//   /// This ensures the service is properly initialized before returning
//   static Future<WrongCharacterService> getAsync() async {
//     try {
//       final service = await getIt.getAsync<WrongCharacterService>();
//       _cachedService = service;
//       AppLogger.debug('WrongCharacterService retrieved asynchronously');
//       return service;
//     } catch (e) {
//       AppLogger.error('Error getting WrongCharacterService async: $e');
//       throw Exception('Failed to get WrongCharacterService: $e');
//     }
//   }

//   /// Checks if the service is ready and initialized
//   static bool get isReady {
//     final service = instance;
//     return service != null && service.isInitialized;
//   }

//   /// Clears the cached service instance
//   static void clearCache() {
//     _cachedService = null;
//   }
// }
