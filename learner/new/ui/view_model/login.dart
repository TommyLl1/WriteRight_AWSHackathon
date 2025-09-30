import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:writeright/new/data/services/auth_service.dart';
import 'package:writeright/new/data/services/image_cache.dart';
import 'package:writeright/new/utils/logger.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService authService;
  final CommonImageCache imageCache;

  LoginViewModel(this.authService, this.imageCache) {
    AppLogger.debug('LoginViewModel: Initializing background image');
    // Initialize background image
    _backgroundImage = imageCache.getBackgroundWidget(darkened: true);
    _iconImage = imageCache.getCharacterWidget(withGlow: false);
    notifyListeners();
  }

  bool _remberMe = false;
  bool get rememberMe => _remberMe;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorMessage;
  bool isLoading = false;

  /// Background and icon images
  late Widget _backgroundImage;
  Widget get backgroundImage => _backgroundImage;
  late Widget _iconImage;
  Widget get iconImage => _iconImage;
  final double iconSize = 100.0;

  // Validate email
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  // Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // Toggle remember me state
  void toggleRememberMe(bool? value) {
    if (value != null) {
      _remberMe = value;
      notifyListeners();
    }
  }

  // Login user with email and password
  Future<void> login(BuildContext context, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;

    isLoading = true;
    notifyListeners();

    try {
      await authService.login(email: email, password: password);
      // Navigate to home page on successful login
      if (context.mounted) {
        context.go('/home');
      }
    } catch (e) {
      errorMessage = 'Login failed: ${e.toString()}';
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Login with Google
  void loginWithGoogle() {
    // TODO: Implement Google login
    errorMessage = 'Google login will be implemented soon';
    notifyListeners();
  }

  // Login with Facebook
  void loginWithFacebook() {
    // TODO: Implement Facebook login
    errorMessage = 'Facebook login will be implemented soon';
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
