import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Custom log printer that includes file information and clean formatting
class AppLogPrinter extends LogPrinter {
  static const int methodCount = 2;
  static const int errorMethodCount = 8;
  static const int lineLength = 120;

  @override
  List<String> log(LogEvent event) {
    var messageStr = _stringifyMessage(event.message);
    var errorStr = event.error != null ? '  ERROR: ${event.error}' : '';

    return [_formatLogLine(event.level, messageStr, errorStr)];
  }

  String _stringifyMessage(dynamic message) {
    if (message is String) return message;
    if (message is Function) return message.toString();
    return message.toString();
  }

  String _formatLogLine(Level level, String message, String error) {
    var emoji = _getEmojiForLevel(level);
    var levelStr = level.name.toUpperCase().padRight(7);
    var timeStr = DateTime.now().toString().substring(11, 23); // HH:mm:ss.SSS
    var color = _getColorForLevel(level);
    return '[${color}m$emoji [$timeStr] [$levelStr] $message$error[0m';
  }

  String _getColorForLevel(Level level) {
    switch (level) {
      case Level.trace:
        return '36'; // Cyan
      case Level.debug:
        return '35'; // Magenta
      case Level.info:
        return '34'; // Blue
      case Level.warning:
        return '33'; // Yellow
      case Level.error:
        return '31'; // Red
      case Level.fatal:
        return '41;97'; // White on Red background
      default:
        return '0'; // Default
    }
  }

  String _getEmojiForLevel(Level level) {
    switch (level) {
      case Level.trace:
        return '🔍';
      case Level.debug:
        return '🐛';
      case Level.info:
        return 'ℹ️';
      case Level.warning:
        return '⚠️';
      case Level.error:
        return '❌';
      case Level.fatal:
        return '💀';
      default:
        return '📝';
    }
  }
}

/// Application logger with automatic initialization and clean API
class AppLogger {
  static Logger? _logger;

  /// Get the logger instance, initializing it if necessary
  static Logger get _instance {
    _logger ??= _createLogger();
    return _logger!;
  }

  /// Create and configure the logger
  static Logger _createLogger() {
    return Logger(
      printer: kDebugMode
          ? AppLogPrinter()
          : PrettyPrinter(
              methodCount: 0,
              errorMethodCount: 3,
              lineLength: 50,
              colors: false,
              printEmojis: false,
              dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
            ),
      level: kDebugMode ? Level.debug : Level.info,
      output: ConsoleOutput(),
    );
  }

  /// Initialize the logger with custom settings (optional)
  static void initialize({
    Level? level,
    LogPrinter? printer,
    LogOutput? output,
  }) {
    _logger = Logger(
      printer: printer ??
          (kDebugMode
              ? AppLogPrinter()
              : PrettyPrinter(
                  methodCount: 0,
                  errorMethodCount: 3,
                  lineLength: 50,
                  colors: false,
                  printEmojis: false,
                  dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
                )),
      level: level ?? (kDebugMode ? Level.debug : Level.info),
      output: output ?? ConsoleOutput(),
    );
  }

  /// Log a trace message (most verbose)
  static void trace(String message, [dynamic error, StackTrace? stackTrace]) {
    _instance.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log a debug message
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _instance.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _instance.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _instance.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log an error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _instance.e(message,
        error: error, stackTrace: stackTrace ?? StackTrace.current);
  }

  /// Log a fatal error message
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _instance.f(message,
        error: error, stackTrace: stackTrace ?? StackTrace.current);
  }

  /// Log API request details
  static void apiRequest(String method, String url,
      {Map<String, dynamic>? data}) {
    info(
        '🌐 API Request: $method $url${data != null ? '\n  Data: $data' : ''}');
  }

  /// Log API response details
  static void apiResponse(String method, String url, int statusCode,
      {dynamic data}) {
    if (statusCode >= 200 && statusCode < 300) {
      info(
          '✅ API Response: $method $url [$statusCode]${data != null ? '\n  Data: $data' : ''}');
    } else {
      warning(
          '⚠️ API Response: $method $url [$statusCode]${data != null ? '\n  Data: $data' : ''}');
    }
  }

  /// Log API error details
  static void apiError(String method, String url, dynamic error,
      [StackTrace? stackTrace]) {
    AppLogger.error('🚫 API Error: $method $url', error, stackTrace);
  }

  /// Log user action
  static void userAction(String action, {Map<String, dynamic>? context}) {
    info(
        '👤 User Action: $action${context != null ? '\n  Context: $context' : ''}');
  }

  /// Log navigation events
  static void navigation(String from, String to,
      {Map<String, dynamic>? params}) {
    info(
        '🧭 Navigation: $from → $to${params != null ? '\n  Params: $params' : ''}');
  }

  /// Log game events
  static void gameEvent(String event, {Map<String, dynamic>? data}) {
    info('🎮 Game Event: $event${data != null ? '\n  Data: $data' : ''}');
  }
}
