import 'logger.dart';

/// Examples of how to use the AppLogger throughout your application
class LoggerExamples {
  
  /// Example: Logging in a page or widget
  static void pageLifecycleExample() {
    // Page initialization
    AppLogger.info('LoginPage initialized');
    
    // User actions
    AppLogger.userAction('User tapped login button', context: {
      'username': 'john_doe',
      'hasRememberMe': true,
    });
    
    // Navigation
    AppLogger.navigation('LoginPage', 'HomePage');
  }
  
  /// Example: API call logging
  static void apiCallExample() {
    final String method = 'POST';
    final String url = '/api/auth/login';
    final Map<String, dynamic> requestData = {
      'username': 'john_doe',
      'password': '***hidden***'
    };
    
    // Log API request
    AppLogger.apiRequest(method, url, data: requestData);
    
    // Simulate successful response
    AppLogger.apiResponse(method, url, 200, data: {'token': 'abc123', 'userId': 456});
    
    // Simulate error response
    AppLogger.apiError(method, url, 'Invalid credentials');
  }
  
  /// Example: Game events logging
  static void gameEventExample() {
    AppLogger.gameEvent('Exercise started', data: {
      'exerciseId': 'ex_123',
      'difficulty': 'medium',
      'timeLimit': 60,
    });
    
    AppLogger.gameEvent('User answered', data: {
      'questionId': 'q_456',
      'userAnswer': 'correct',
      'timeElapsed': 15.5,
    });
    
    AppLogger.gameEvent('Exercise completed', data: {
      'score': 85,
      'totalQuestions': 10,
      'correctAnswers': 8,
    });
  }
  
  /// Example: Error handling
  static void errorHandlingExample() {
    try {
      // Some operation that might fail
      throw Exception('Something went wrong');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to process user data', error, stackTrace);
    }
  }
  
  /// Example: Debug information
  static void debugExample() {
    AppLogger.debug('Loading user preferences');
    AppLogger.debug('Cache hit ratio: 85%');
    AppLogger.trace('Detailed trace information for debugging');
  }
  
  /// Example: Warning situations
  static void warningExample() {
    AppLogger.warning('Low memory warning - clearing cache');
    AppLogger.warning('Slow network detected, switching to offline mode');
  }
}
