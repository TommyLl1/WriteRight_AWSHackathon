import 'dart:math';
import 'package:flutter/material.dart';
import 'package:writeright/new/data/api_service.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/data/models/user.dart';
import 'package:writeright/new/data/services/user.dart';

class ProfileViewModel extends ChangeNotifier {
  final ApiService apiService;
  final UserRepository userRepository;
  ProfileViewModel({required this.apiService})
    : userRepository = UserRepository(apiService);

  /// User profile data
  User? _user;
  User? get user => _user;

  int get expMax => _user != null ? xpForLevel(_user!.level + 1) : 0;

  /// Loading state for profile
  bool _profileLoading = false;
  bool get isProfileLoading => _profileLoading;
  bool _initialized = false;
  bool get isInitialized => _initialized;
  bool _isProfileError = false;
  bool get isProfileError => _isProfileError;

  /// XP needed to reach a level: xp = 10 * (level)^(3/2)
  int xpForLevel(num level) {
    return (10 * pow(level.toDouble(), 1.5)).ceil();
  }

  double get xpProgress {
    if (_user == null) return 0.0;
    final int nextLevelXp = xpForLevel(_user!.level + 1);
    final int thisLevelXp = xpForLevel(_user!.level);
    if (nextLevelXp == thisLevelXp) return 0.0;
    return (_user!.exp - thisLevelXp) / (nextLevelXp - thisLevelXp);
  }

  /// Fetches and caches the user profile from the API only when required
  Future<void> initialize() async {
    if (_profileLoading || _initialized) {
      AppLogger.debug('Profile already loading or ready, skipping fetch');
      return;
    }
    _profileLoading = true;
    notifyListeners();
    try {
      _user = await userRepository.getUserProfile();
      _initialized = true;
      _profileLoading = false;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to fetch user profile: $e');
      _profileLoading = false;
      _isProfileError = true;
      notifyListeners();
    }
  }
}
