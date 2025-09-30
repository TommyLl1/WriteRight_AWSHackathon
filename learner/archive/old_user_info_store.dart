// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'api_service.dart';
// import '../utils/logger.dart';

// class UserInfoStore extends ChangeNotifier {
//   int _level = 1;
//   int _exp = 0;
//   bool _isLoading = true;
//   Map<String, dynamic>? _profile;
//   bool _profileLoading = false;

//   int get level => _level;
//   int get exp => _exp;
//   bool get isLoading => _isLoading;
//   Map<String, dynamic>? get profile => _profile;
//   bool get isProfileLoading => _profileLoading;
//   bool get isProfileReady =>
//       _profile != null && _profile!.isNotEmpty && !_profileLoading;
//   String? get name => _profile?['name'];
//   String? get email => _profile?['email'];
//   String? get userId => _profile?['user_id'];
//   int get expMax => xpForLevel(_level + 1);

//   /// XP needed to reach a level: xp = 10 * (level)^(3/2)
//   int xpForLevel(num level) {
//     return (10 * pow(level.toDouble(), 1.5)).ceil();
//   }

//   double get xpProgress {
//     final int nextLevelXp = xpForLevel(_level + 1);
//     final int thisLevelXp = xpForLevel(_level);
//     if (nextLevelXp == thisLevelXp) return 0.0;
//     return (_exp - thisLevelXp) / (nextLevelXp - thisLevelXp);
//   }

//   Future<void> loadFromCache() async {
//     final prefs = await SharedPreferences.getInstance();
//     _level = prefs.getInt('cachedLevel') ?? 1;
//     _exp = prefs.getInt('cachedExp') ?? 0;
//     _isLoading = false;
//     notifyListeners();
//   }

//   Future<void> fetchAndUpdate() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final response = await (await ApiService.create(prefs)).getUserStatus();
//       final data = response.data;
//       _level = data['level'] ?? 1;
//       _exp = data['exp'] ?? 0;
//       // No need to set expMax, it's calculated
//       await prefs.setInt('cachedLevel', _level);
//       await prefs.setInt('cachedExp', _exp);
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       AppLogger.error('Failed to fetch user status: $e');
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Fetches and caches the user profile from the API only when required
//   Future<void> fetchProfile() async {
//     if (_profileLoading || isProfileReady) {
//       AppLogger.debug('Profile already loading or ready, skipping fetch');
//       return;
//     }
//     _profileLoading = true;
//     notifyListeners();
//     try {
//       final response = await apiService.getUserProfile();
//       _profile = response.data;
//       _profileLoading = false;
//       notifyListeners();
//     } catch (e) {
//       AppLogger.error('Failed to fetch user profile: $e');
//       _profileLoading = false;
//       notifyListeners();
//     }
//   }
// }
