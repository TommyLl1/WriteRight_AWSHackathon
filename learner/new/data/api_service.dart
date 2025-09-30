import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:writeright/main.dart';
import 'package:writeright/new/utils/constants.dart';
import '../utils/logger.dart';

/// TODO: specify response type, use from json

class ApiService {
  final Dio dio;
  final SharedPreferences prefs;

  ApiService(this.dio, this.prefs);

  String? get userId {
    final id = prefs.getString('userId');
    AppLogger.debug('ApiService.userId getter: $id');
    return id;
  }

  // Auth
  Future<Response> login(String email, String password) async {
    AppLogger.debug('ApiService.login called with email: $email');
    final resp = await dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    AppLogger.debug('ApiService.login response: ${resp.statusCode}');
    return resp;
  }

  Future<Response> logout() async {
    AppLogger.debug('ApiService.logout called');
    final resp = await dio.get('/auth/logout');
    AppLogger.debug('ApiService.logout response: ${resp.statusCode}');
    return resp;
  }

  // User Profile
  Future<Response> getUserProfile([String? userId]) async {
    final id = userId ?? this.userId;
    AppLogger.debug('ApiService.getUserProfile called for userId: $id');
    if (id == null) throw Exception('User ID not found');
    final resp = await dio.get(
      '/user/profile',
      queryParameters: {'user_id': id},
    );
    AppLogger.debug('getUserProfile: ${resp.statusCode} ${resp.data}');
    return resp;
  }

  Future<Response> getUserStatus([String? userId]) async {
    final id = userId ?? this.userId;
    AppLogger.debug('ApiService.getUserStatus called for userId: $id');
    if (id == null) throw Exception('User ID not found');
    final resp = await dio.get(
      '/user/status',
      queryParameters: {'user_id': id},
    );
    AppLogger.debug('getUserStatus: ${resp.statusCode} ${resp.data}');
    return resp;
  }

  // User Tasks
  Future<Response> getCurrentTasks([String? userId]) async {
    final id = userId ?? this.userId;
    AppLogger.debug('ApiService.getCurrentTasks called for userId: $id');
    if (id == null) throw Exception('User ID not found');
    final resp = await dio.get(
      '/user/tasks/current',
      queryParameters: {'user_id': id},
    );
    AppLogger.debug('ApiService.getCurrentTasks response: ${resp.statusCode}');
    return resp;
  }

  Future<Response> setTaskProgress({
    String? userId,
    required String taskId,
    required int progress,
  }) async {
    final id = userId ?? this.userId;
    AppLogger.debug(
      'ApiService.setTaskProgress called for userId: $id, taskId: $taskId, progress: $progress',
    );
    if (id == null) throw Exception('User ID not found');
    final resp = await dio.post(
      '/user/tasks/progress',
      data: {'user_id': id, 'task_id': taskId, 'progress': progress},
    );
    AppLogger.debug('ApiService.setTaskProgress response: ${resp.statusCode}');
    return resp;
  }

  // Wrong Words
  Future<Response> getUserWrongWords({
    String? userId,
    bool? noPaging,
    int? page,
    int? pageSize,
  }) async {
    final id = userId ?? this.userId;
    AppLogger.debug('ApiService.getUserWrongWords called for userId: $id');
    if (id == null) throw Exception('User ID not found');
    final params = {
      'user_id': id,
      if (noPaging != null) 'no_paging': noPaging,
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    };
    final resp = await dio.get('/user/wrong-words', queryParameters: params);
    AppLogger.debug(
      'ApiService.getUserWrongWords response: ${resp.statusCode}',
    );
    return resp;
  }

  Future<Response> addWrongWord({String? userId, required String word}) async {
    final id = userId ?? this.userId;
    AppLogger.debug(
      'ApiService.addWrongWord called for userId: $id, word: $word',
    );
    if (id == null) throw Exception('User ID not found');
    final resp = await dio.post(
      '/user/wrong-words',
      data: {'user_id': id, 'word': word},
    );
    AppLogger.debug('ApiService.addWrongWord response: ${resp.statusCode}');
    return resp;
  }

  Future<Response> getUserWrongWordCount([String? userId]) async {
    final id = userId ?? this.userId;
    AppLogger.debug('ApiService.getUserWrongWordCount called for userId: $id');
    if (id == null) throw Exception('User ID not found');
    final resp = await dio.get(
      '/user/wrong-words/count',
      queryParameters: {'user_id': id},
    );
    AppLogger.debug(
      'ApiService.getUserWrongWordCount response: [${resp.statusCode}',
    );
    return resp;
  }

  // Game
  Future<Response> startGame({String? userId, int? qCount}) async {
    final id = userId ?? this.userId;
    AppLogger.debug(
      'ApiService.startGame called for userId: $id, qCount: $qCount',
    );
    if (id == null) throw Exception('User ID not found');
    final params = {if (qCount != null) 'qCount': qCount};
    final resp = await dio.get('/game/start/$id', queryParameters: params);
    AppLogger.debug('ApiService.startGame response: ${resp.statusCode}');
    return resp;
  }

  Future<Response> submitGameResult({required String gameData}) async {
    try {
      final resp = await dio.post('/game/submit-result', data: gameData);
      AppLogger.debug(
        'ApiService.submitGameResult called with gameData: $gameData',
      );
      return resp;
    } catch (e) {
      if (e is DioException) {
        // Try to extract the error response JSON
        final responseData = e.response?.data;
        AppLogger.error(
          'ApiService.submitGameResult error: ${e.message}, Response: ${responseData ?? "No response data"}',
        );
      } else {
        AppLogger.error('ApiService.submitGameResult error: $e');
      }
      rethrow;
    }
  }

  // User Registration
  Future<Response> registerUser({
    required String username,
    required String email,
  }) async {
    AppLogger.debug(
      'ApiService.registerUser called for username: $username, email: $email',
    );
    final resp = await dio.post(
      '/user/register',
      data: {'username': username, 'email': email},
    );
    AppLogger.debug('ApiService.registerUser response: ${resp.statusCode}');
    return resp;
  }

  // User Settings
  Future<Response> getUserSettings([String? userId]) async {
    final id = userId ?? this.userId;
    AppLogger.debug('ApiService.getUserSettings called for userId: $id');
    if (id == null) throw Exception('User ID not found');
    final resp = await dio.get(
      '/user/settings',
      queryParameters: {'user_id': id},
    );
    AppLogger.debug('ApiService.getUserSettings response: ${resp.statusCode}');
    return resp;
  }

  Future<Response> updateUserSettings({
    String? userId,
    String? language,
    String? theme,
    Map<String, dynamic>? settings,
  }) async {
    final id = userId ?? this.userId;
    AppLogger.debug('ApiService.updateUserSettings called for userId: $id');
    if (id == null) throw Exception('User ID not found');
    final body = <String, dynamic>{
      if (language != null) 'language': language,
      if (theme != null) 'theme': theme,
      if (settings != null) 'settings': settings,
    };
    final resp = await dio.post(
      '/user/settings',
      queryParameters: {'user_id': id},
      data: body,
    );
    AppLogger.debug(
      'ApiService.updateUserSettings response: ${resp.statusCode}',
    );
    return resp;
  }

  // Health
  Future<Response> healthCheck() async {
    AppLogger.debug('ApiService.healthCheck called');
    final resp = await dio.get('/health');
    AppLogger.debug('ApiService.healthCheck response: ${resp.statusCode}');
    return resp;
  }

  // Handwriting Answer Check
  Future<Response> checkHandwriteAnswer({
    required String targetWord,
    required String imagePath,
    required String gameId,
  }) async {
    String userId = prefs.getString('userId')!;
    AppLogger.debug(
      'ApiService.checkHandwriteAnswer called for userId: $userId',
    );
    dio.options.connectTimeout = Duration(minutes: 3);
    AppLogger.debug(
      'ApiService.checkHandwriteAnswer called with targetWord: $targetWord, imagePath: $imagePath, gameId: $gameId',
    );
    final payload = {
      'user_id': userId,
      'target_word': targetWord,
      'image_url': imagePath,
      'game_id': gameId, // Added gameId to the payload
    };
    final resp = await dio.post('/game/check-handwrite-answer', data: payload);
    AppLogger.debug(
      'ApiService.checkHandwriteAnswer response: ${resp.statusCode}',
    );
    return resp;
  }

  // Flag Question
  Future<bool> flagQuestion({
    required String questionId,
    String? userId,
    String? reason,
    String? notes,
  }) async {
    final id = userId ?? this.userId;
    AppLogger.debug(
      'ApiService.flagQuestion called for userId: $id, questionId: $questionId, reason: $reason, notes: $notes',
    );
    if (id == null) throw Exception('User ID not found');
    final body = {
      'question_id': questionId,
      'user_id': id,
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
    };
    final resp = await dio.post('/game/flag-questions', data: body);
    AppLogger.debug('ApiService.flagQuestion response: ${resp.statusCode}');
    return resp.statusCode == 200 || resp.statusCode == 201;
  }

  Future<Response> uploadFile({
    XFile? imageFile,
    Uint8List? webImageBytes,
  }) async {
    AppLogger.debug("ApiService.uploadFile called");
    String userId = prefs.getString('userId')!;
    if (imageFile == null && webImageBytes == null) {
      throw Exception('Either imageFile or webImageBytes must be provided');
    }

    final dioInstance = Dio(
      BaseOptions(baseUrl: await AppConstants.imagePostAPIUrl),
    )..interceptors.addAll(dio.interceptors);

    final formData = FormData.fromMap({
      if (imageFile != null)
        'file': await MultipartFile.fromFile(imageFile.path),
      if (webImageBytes != null)
        'file': MultipartFile.fromBytes(webImageBytes, filename: 'upload.jpg'),
    });

    final resp = await dioInstance.post('', data: formData);
    AppLogger.debug('ApiService.uploadFile response: ${resp.statusCode}');
    return resp;
  }

  Future<Response> scanningWrongWords({required String uploadedUrl}) async {
    String userId = prefs.getString('userId')!;

    AppLogger.debug(
      'ApiService.scanningWrongWords called for userId: $userId, uploadedUrl: $uploadedUrl',
    );
    final body = {'user_id': userId, 'uploaded_url': uploadedUrl};

    /// Set timeout to 2 minutes
    /// TODO: turn retry off?
    dio.options.connectTimeout = Duration(minutes: 5);

    final resp = await dio.post('/user/wrong-words/scanning', data: body);
    AppLogger.debug(
      'ApiService.scanningWrongWords response: ${resp.statusCode}',
    );
    return resp;
  }

  Future<Response> uploadFileForWeb({required Uint8List? webImageBytes}) async {
    AppLogger.debug("ApiService.uploadFileForWeb called");
    if (webImageBytes == null) {
      throw Exception('webImageBytes must be provided');
    }

    /// TODO: remove this if needed
    final dioInstance = Dio(
      BaseOptions(baseUrl: await AppConstants.imagePostAPIUrl),
    )..interceptors.addAll(dio.interceptors);

    AppLogger.debug("baseUrl: ${dioInstance.options.baseUrl}");

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(webImageBytes, filename: 'upload.jpg'),
    });

    final resp = await dioInstance.post('', data: formData);
    AppLogger.debug('ApiService.uploadFileForWeb response: ${resp.statusCode}');

    return resp;
  }
}
