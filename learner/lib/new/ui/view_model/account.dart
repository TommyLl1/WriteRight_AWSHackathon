import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:writeright/new/data/api_service.dart';
import 'package:writeright/new/data/services/auth_service.dart';
import 'package:writeright/new/utils/logger.dart';

class AccountViewModel extends ChangeNotifier {
  final ApiService apiService;
  final AuthService authService;

  AccountViewModel({
    required this.apiService,
    required this.authService,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Logout the user
  Future<void> logout(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.info('Starting logout process');
      
      // Call the logout API endpoint
      await apiService.logout();
      AppLogger.debug('Logout API call successful');
      
      // Clear local session data
      await authService.logout();
      AppLogger.debug('Local session cleared');
      
      // Navigate to login page
      if (context.mounted) {
        context.go('/login');
        AppLogger.info('Logout successful, navigated to login page');
      }
    } catch (e) {
      AppLogger.error('Logout failed: $e');
      _errorMessage = '登出失敗，請再試一次';
      
      // Even if API call fails, still clear local session and redirect
      try {
        await authService.logout();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (localError) {
        AppLogger.error('Failed to clear local session: $localError');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
