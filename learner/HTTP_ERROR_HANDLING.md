# HTTP Error Handling Implementation

## Overview
Enhanced the word scanning functionality with proper HTTP error code handling to provide meaningful user feedback for different error scenarios.

## Changes Made

### 1. Custom Exception Classes (`lib/new/utils/exceptions.dart`)
Created specialized exception classes to handle different HTTP error scenarios:

- **`ServerUnavailableException`** (502, 503): Backend is down or unavailable
- **`ServerErrorException`** (500): Server error when processing request  
- **`InvalidInputException`** (422): Invalid user input or no words found in image
- **`NetworkException`**: Network connectivity issues
- **`HttpExceptionFactory`**: Utility to create appropriate exceptions from status codes

### 2. Enhanced `WrongCharacterService` Error Handling
Updated all API methods in `wrong_character.dart` to:

- Handle specific HTTP status codes with meaningful messages
- Convert `DioException` to appropriate custom exceptions
- Provide Chinese error messages for better user experience
- Use consistent error handling pattern across all methods

**Key Methods Updated:**
- `uploadAndScan()` - Main scanning functionality
- `searchCharacters()` - Character search
- `getAllCharacters()` - Paginated character retrieval
- `loadAllCharacters()` - Bulk character loading
- `addWrongWord()` - Adding new wrong words
- `getTotalCount()` - Getting total count

### 3. Enhanced `GetPhotoViewModel` Error Handling
Updated the `startScanning()` method in `word_scanning.dart` to:

- Handle different exception types with specific error messages
- Provide user-friendly Chinese error messages
- Reset error state properly between scans

## Error Scenarios Handled

### HTTP Status Codes
- **422**: "圖片中未找到錯字，請嘗試其他圖片" (No words found in image)
- **500**: "伺服器處理請求時發生錯誤" (Server processing error)
- **502/503**: "伺服器暫時無法使用，請稍後再試" (Server unavailable)

### Network Issues
- Connection timeout: "連線逾時，請檢查網路連線或稍後再試"
- Connection error: "網路連線錯誤，請檢查網路連線"
- General network error: "網路錯誤: [specific message]"

### Default Fallback
- Unknown errors: "掃描失敗，請稍後再試" with optional error code

## Benefits

1. **Better User Experience**: Users get clear, actionable error messages in Chinese
2. **Easier Debugging**: Developers can identify specific error types
3. **Consistent Error Handling**: All API methods use the same error handling pattern
4. **Maintainable Code**: Centralized exception handling logic
5. **Robust Error Recovery**: Proper exception re-throwing preserves error context

## Usage Example

```dart
try {
  final response = await wrongCharacterService.uploadAndScan(
    imageFile: imageFile,
  );
  // Handle success
} on InvalidInputException catch (e) {
  // Show "No words found" message
  showError('圖片中未找到錯字，請嘗試其他圖片');
} on ServerUnavailableException catch (e) {
  // Show "Server down" message
  showError('伺服器暫時無法使用，請稍後再試');
} on NetworkException catch (e) {
  // Show network error message
  showError(e.message);
} catch (e) {
  // Show generic error message
  showError('掃描失敗，請稍後再試');
}
```

## Future Enhancements

1. **Retry Logic**: Implement automatic retry for certain error types (502, 503)
2. **Offline Support**: Cache results and handle offline scenarios
3. **Rate Limiting**: Handle 429 Too Many Requests errors
4. **Analytics**: Track error rates for different scenarios
5. **User Feedback**: Allow users to report persistent errors
