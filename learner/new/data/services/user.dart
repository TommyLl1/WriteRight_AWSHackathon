// repositories/user_repository.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:writeright/new/data/models/user.dart';
import 'package:writeright/new/data/api_service.dart';
import 'package:writeright/new/utils/logger.dart';

class UserRepository {
  static UserRepository? _instance;
  final ApiService apiService;

  // Broadcast stream for user updates
  final StreamController<void> _userUpdateController =
      StreamController.broadcast();
  Stream<void> get onUserUpdate => _userUpdateController.stream;

  // Singleton factory
  factory UserRepository(ApiService apiService) {
    return _instance ??= UserRepository._internal(apiService);
  }

  UserRepository._internal(this.apiService);

  // Cached user status and profile
  // Map<String, dynamic>? _cachedUserStatus;
  User? _cachedUserProfile;

  // Helper to update both caches from a map (status or profile)
  void _updateCachesFromMap(Map<String, dynamic> json,
      {bool isProfile = false}) {
    if (isProfile) {
      _cachedUserProfile = User.fromJson(json);
      // _cachedUserStatus = {
      //   'user_id': json['user_id'],
      //   'name': json['name'],
      //   'level': json['level'],
      //   'exp': json['exp'],
      // };
    } else {
      // _cachedUserStatus = json;
      if (_cachedUserProfile != null) {
        _cachedUserProfile = _cachedUserProfile!.copyWith(
          userId: json['user_id'],
          name: json['name'],
          level: json['level'],
          exp: json['exp'],
        );
      } else {
        _cachedUserProfile = User(
          userId: json['user_id'],
          name: json['name'],
          level: json['level'],
          exp: json['exp'],
          email: json['email'] ?? '',
          createdAt: json['created_at'] ?? 0,
        );
      }
    }
    _userUpdateController.add(null); // Notify listeners
  }

  /// Async getter for cached user status (fetches if null)
  Future<User> getUserStatus([String? userId]) async {
    AppLogger.debug('UserRepository.getUserStatus called with userId: $userId');
    if (_cachedUserProfile != null) return _cachedUserProfile!;
    return await fetchUserStatus(userId);
  }

  /// Async getter for cached user profile (fetches if null)
  Future<User> getUserProfile([String? userId]) async {
    AppLogger.debug(
        'UserRepository.getUserProfile called with userId: $userId');
    if (_cachedUserProfile != null && _cachedUserProfile?.createdAt != 0) {
      return _cachedUserProfile!;
    }
    return await fetchUserProfile(userId);
  }

  /// Load cache from provided JSON (status or profile)
  void loadCacheFromJson(Map<String, dynamic> json, {bool isProfile = false}) {
    _updateCachesFromMap(json, isProfile: isProfile);
  }

  /// Fetch user profile (detailed) and update both caches
  Future<User> fetchUserProfile([String? userId]) async {
    AppLogger.debug(
        'UserRepository.fetchUserProfile called with userId: $userId');
    try {
      final response = await apiService.getUserProfile(userId);
      if (response.statusCode == 200) {
        _updateCachesFromMap(response.data, isProfile: true);
        return _cachedUserProfile!;
      } else {
        throw Exception(
            'Failed to fetch user profile: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception(
          'Error fetching user profile: ${e.response?.data['message'] ?? e.message}');
    }
  }

  /// Fetch user status (simplified) and update both caches
  Future<User> fetchUserStatus([String? userId]) async {
    AppLogger.debug(
        'UserRepository.fetchUserStatus called with userId: $userId');
    try {
      final response = await apiService.getUserStatus(userId);
      if (response.statusCode == 200) {
        _updateCachesFromMap(response.data, isProfile: false);
        return _cachedUserProfile!;
      } else {
        throw Exception(
            'Failed to fetch user status: \\${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception(
          'Error fetching user status: \\${e.response?.data['message'] ?? e.message}');
    }
  }

  /// Fetch current tasks
  Future<List<dynamic>> fetchCurrentTasks([String? userId]) async {
    try {
      final response = await apiService.getCurrentTasks(userId);
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception(
            'Failed to fetch current tasks: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception(
          'Error fetching current tasks: ${e.response?.data['message'] ?? e.message}');
    }
  }

  /// Update task progress
  Future<void> updateTaskProgress({
    String? userId,
    required String taskId,
    required int progress,
  }) async {
    try {
      final response = await apiService.setTaskProgress(
        userId: userId,
        taskId: taskId,
        progress: progress,
      );
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update task progress: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception(
          'Error updating task progress: ${e.response?.data['message'] ?? e.message}');
    }
  }

  void dispose() {
    _userUpdateController.close();
  }
}
