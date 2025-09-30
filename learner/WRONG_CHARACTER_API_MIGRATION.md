# Migration Guide: Mock to API Service

This guide helps migrate from the mock `WrongCharacterService` to the new API-integrated version.

## Quick Migration Checklist

### ✅ Completed (Auto-migrated)

- [x] Created new API-integrated `WrongCharacterService`
- [x] Updated dependency injection in `dependencies.dart`
- [x] Created `WrongCharacterServiceFactory` for easy access
- [x] Updated `wrong_character_page.dart` to use new service
- [x] Added proper error handling and logging
- [x] Maintained same interface for backward compatibility

### 📋 Manual Steps (If needed)

1. **Verify API Configuration**
   - Ensure `ApiService` base URL is correctly configured
   - Check that user ID is properly set in SharedPreferences
   - Verify network connectivity for API calls

2. **Test the Integration**
   ```bash
   flutter test test/wrong_character_service_test.dart
   ```

3. **Remove Old Service (Optional)**
   - Once verified working, you can delete `wrong_character_service_old.dart`
   - Update any remaining imports if needed

## Code Changes Made

### Before (Mock Service)
```dart
class _MyPageState extends State<MyPage> {
  final WrongCharacterService _service = WrongCharacterService();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final response = await _service.getAllCharacters();
    // Use response...
  }
}
```

### After (API Service)
```dart
class _MyPageState extends State<MyPage> {
  WrongCharacterService? _service;
  
  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    try {
      _service = await WrongCharacterServiceFactory.getAsync();
      _loadData();
    } catch (e) {
      // Handle initialization error
      _showError('Service initialization failed');
    }
  }
  
  Future<void> _loadData() async {
    if (_service == null) return;
    
    try {
      final response = await _service!.getAllCharacters();
      // Use response...
    } catch (e) {
      // Handle API error
      _showError('Failed to load data');
    }
  }
}
```

## Key Differences

| Aspect             | Mock Service     | API Service         |
| ------------------ | ---------------- | ------------------- |
| **Initialization** | Synchronous      | Asynchronous        |
| **Data Source**    | Local mock data  | Remote API          |
| **Error Handling** | Simulated delays | Real network errors |
| **Dependencies**   | None             | Requires ApiService |
| **Performance**    | Instant          | Network dependent   |

## Error Handling Patterns

### Network Errors
```dart
try {
  final response = await service.getAllCharacters();
  // Success
} on DioException catch (e) {
  // Network-specific error
  _showError('Network error: ${e.message}');
} catch (e) {
  // General error
  _showError('Unexpected error: $e');
}
```

### Service Not Ready
```dart
final service = WrongCharacterServiceFactory.instance;
if (service == null || !service.isInitialized) {
  _showError('Service not ready. Please try again.');
  return;
}
```

## Testing Changes

### Mock Service Testing
- Used immediate responses
- No network dependencies
- Predictable data

### API Service Testing
- Requires mock API responses
- Network error simulation
- Async initialization testing

## Troubleshooting

### Common Issues

1. **Service Not Initialized**
   - Ensure `setupDependencies()` is called in `main()`
   - Use `WrongCharacterServiceFactory.getAsync()` for initialization
   - Check that ApiService is properly configured

2. **Network Errors**
   - Verify API base URL in constants
   - Check network connectivity
   - Ensure proper authentication headers

3. **Data Format Issues**
   - Verify API response matches `WrongCharacter.fromJson()`
   - Check timestamp format (Unix vs milliseconds)
   - Validate required fields are present

### Debug Commands

```dart
// Check service status
print('Service ready: ${WrongCharacterServiceFactory.isReady}');
print('User ID: ${service.currentUserId}');

// Test API connectivity
try {
  final apiService = await getIt.getAsync<ApiService>();
  final response = await apiService.healthCheck();
  print('API Health: ${response.statusCode}');
} catch (e) {
  print('API Health Check Failed: $e');
}
```

## Performance Considerations

- **Caching**: Consider implementing local caching for frequently accessed data
- **Pagination**: API service supports pagination, use it for large datasets
- **Error Recovery**: Implement retry logic for transient network errors
- **Loading States**: Show appropriate loading indicators during API calls

## Next Steps

1. Monitor API performance and error rates
2. Implement caching if needed
3. Add offline support if required
4. Consider implementing data synchronization
5. Remove old mock service once stable
