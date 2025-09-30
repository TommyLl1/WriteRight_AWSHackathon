# AppLogger - WriteRight Logging Framework

A robust logging framework for the WriteRight Flutter application, built on top of the `logger` package.

## Features

- ✅ **Automatic initialization** - No need to manually initialize unless you want custom settings
- 🎯 **Smart log levels** - Debug logs in development, info+ in production
- 🎨 **Beautiful formatting** - Emojis, timestamps, and clean layout
- 🔧 **Specialized methods** - API calls, user actions, game events, navigation
- 📱 **Flutter-aware** - Uses Flutter's `kDebugMode` for appropriate logging levels

## Basic Usage

```dart
import 'package:writeright/utils/logger.dart';

// Basic logging (no initialization needed!)
AppLogger.debug('Debug information');
AppLogger.info('General information');
AppLogger.warning('Something to watch out for');
AppLogger.error('An error occurred', error, stackTrace);
```

## Specialized Logging Methods

### API Calls
```dart
// Log API requests
AppLogger.apiRequest('POST', '/api/auth/login', data: {'username': 'john'});

// Log API responses
AppLogger.apiResponse('POST', '/api/auth/login', 200, data: {'token': 'abc123'});

// Log API errors
AppLogger.apiError('POST', '/api/auth/login', error);
```

### User Actions
```dart
AppLogger.userAction('User tapped login button', context: {
  'username': 'john_doe',
  'hasRememberMe': true,
});
```

### Navigation
```dart
AppLogger.navigation('LoginPage', 'HomePage', params: {'userId': 123});
```

### Game Events
```dart
AppLogger.gameEvent('Exercise completed', data: {
  'score': 85,
  'totalQuestions': 10,
  'correctAnswers': 8,
});
```

## Custom Initialization (Optional)

```dart
import 'package:logger/logger.dart';

// Custom initialization with specific log level
AppLogger.initialize(level: Level.warning);

// Or with a custom printer
AppLogger.initialize(
  level: Level.info,
  printer: PrettyPrinter(),
);
```

## Log Levels

1. **trace** 🔍 - Most verbose, for deep debugging
2. **debug** 🐛 - Development debugging information
3. **info** ℹ️ - General application information
4. **warning** ⚠️ - Something that should be noted
5. **error** ❌ - Errors that occurred
6. **fatal** 💀 - Critical errors

## Best Practices

1. **Use appropriate log levels** - Don't log everything as error
2. **Include context** - Add relevant data to help with debugging
3. **Use specialized methods** - They provide better structure
4. **Don't log sensitive data** - Passwords, tokens, etc.
5. **Use meaningful messages** - Make logs searchable and useful

## Examples

See `lib/utils/logger_examples.dart` for comprehensive usage examples.

## Output Format

In debug mode, logs appear as:
```
🐛 [14:30:15.123] [DEBUG  ] User tapped login button
ℹ️ [14:30:15.456] [INFO   ] 🌐 API Request: POST /api/auth/login
✅ [14:30:15.789] [INFO   ] ✅ API Response: POST /api/auth/login [200]
```

In production, logs use a more compact format without emojis for better performance.
