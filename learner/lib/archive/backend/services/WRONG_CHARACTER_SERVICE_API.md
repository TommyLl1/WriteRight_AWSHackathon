# Wrong Character Service - API Integration

This document explains the new API-integrated `WrongCharacterService` that replaces the mock data service.

## Overview

The new `WrongCharacterService` uses real API calls instead of mock data, providing the same interface and functionality while fetching data from the backend server.

## Architecture

### Files Created/Modified

1. **`lib/backend/services/wrong_character_service.dart`** - New service that uses API calls
2. **`lib/backend/factories/wrong_character_service_factory.dart`** - Factory for easy service access
3. **`lib/backend/services/dependencies.dart`** - Updated to include new service registration
4. **`lib/backend/backend.dart`** - Updated to export the factory
5. **`lib/wrong_character_page.dart`** - Updated to use the new service

### Key Changes

- **Dependency Injection**: Uses `get_it` for proper service registration and initialization
- **Async Service Factory**: Ensures `ApiService` is ready before initializing `WrongCharacterService`
- **Error Handling**: Comprehensive error handling with logging
- **API Integration**: All methods now call actual API endpoints

## Service Methods

The service maintains the same interface as the old mock service:

### Core Methods

```dart
// Get paginated characters
Future<WrongCharacterResponse> getAllCharacters({
  int page = 1,
  int pageSize = 100,
  String? userId,
})

// Search with pagination
Future<WrongCharacterResponse> searchCharacters(
  String query, {
  int page = 1,
  int pageSize = 100,
  String? userId,
})

// Load all characters at once (no pagination)
Future<List<WrongCharacter>> loadAllCharacters({
  String? userId,
})

// Get specific character by ID or text
Future<WrongCharacter?> getCharacterById(int wordId)
Future<WrongCharacter?> getCharacterByText(String characterText)

// Add new wrong word
Future<bool> addWrongWord(String word, {String? userId})
```

### Utility Methods

```dart
// Check if service is initialized
bool get isInitialized

// Get current user ID
String? get currentUserId
```

## Usage

### In UI Components

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  WrongCharacterService? _characterService;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      _characterService = await WrongCharacterServiceFactory.getAsync();
      // Service is ready, load data
      _loadData();
    } catch (e) {
      // Handle initialization error
      print('Failed to initialize service: $e');
    }
  }

  Future<void> _loadData() async {
    if (_characterService == null) return;
    
    try {
      final response = await _characterService!.getAllCharacters();
      // Use response.items
    } catch (e) {
      // Handle API error
      print('Failed to load data: $e');
    }
  }
}
```

### Direct Access (if service is already initialized)

```dart
final service = WrongCharacterServiceFactory.instance;
if (service != null && service.isInitialized) {
  final response = await service.getAllCharacters();
}
```

## Error Handling

The service provides comprehensive error handling:

- **Network Errors**: Wrapped `DioException` with user-friendly messages
- **Service Not Initialized**: Clear error when service is used before initialization
- **API Response Errors**: HTTP status code errors are caught and reported
- **Null Safety**: All methods handle null service gracefully

## API Endpoints Used

- `GET /user/wrong-words` - Get user's wrong words with pagination
- `POST /user/wrong-words` - Add a new wrong word

## Logging

All service operations are logged using `AppLogger`:

- Debug logs for method calls and responses
- Error logs for failures
- Info logs for successful operations

## Migration from Old Service

The old service (`wrong_character_service_old.dart`) can be safely removed once you verify the new service is working correctly. The interface is identical, so existing code should work without changes after updating the service initialization pattern.

## Dependencies

- `get_it` - Dependency injection
- `dio` - HTTP client
- `shared_preferences` - Local storage
- Custom `ApiService` - API communication layer
- Custom `AppLogger` - Logging system
