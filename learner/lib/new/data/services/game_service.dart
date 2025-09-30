import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:writeright/new/data/models/game.dart';
import 'package:writeright/new/data/api_service.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/data/models/questions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:writeright/new/data/models/wrong_words.dart';
import 'dart:core';
import 'package:writeright/new/utils/constants.dart';
import 'package:writeright/new/utils/exceptions.dart';

class GameService {
  final ApiService apiService;
  final SharedPreferences prefs;
  GameService(this.apiService, this.prefs);

  Future<GameObject> startGame({int qCount = 10}) async {
    /// Get user ID from preferences
    String? userId = prefs.getString('userId');
    if (userId == null) {
      AppLogger.error('User ID not found in preferences');
      throw Exception('User ID not found');
    }

    /// Fetch start game data from API
    AppLogger.debug('Starting game for user: $userId with $qCount questions');
    Response<dynamic>? response;
    int retries = 3;
    while (retries > 0) {
      try {
        response = await apiService.startGame(userId: userId, qCount: qCount);
        break; // Exit loop if successful
      } catch (e) {
        retries--;
        AppLogger.error(
          'Failed to start game. Retries left: $retries. Error: $e',
        );
        if (retries == 0) {
          throw Exception('Failed to start game after multiple attempts');
        }
        await Future.delayed(Duration(seconds: 2)); // Wait before retrying
      }
    }

    /// Check if response is null after retries
    if (response == null) {
      AppLogger.error('Response is null after retries');
      throw Exception('Failed to start game, no response received');
    }

    /// Occationally, the API might have weird responses
    if (response.data is Map<String, dynamic> &&
        response.data.containsKey("ERROR")) {
      response.data = response.data["ERROR"];
    } // TODO: handle error properly

    /// We need to toJson the questions (idk why)
    /// So loop all questions and convert them
    /// then form the whole GameObject
    List<QuestionBase> questions = [];
    try {
      questions = (response.data["questions"] as List)
          .map<QuestionBase>((q) => QuestionFactory.fromJson(q))
          .toList();
    } catch (e) {
      AppLogger.error("Error parsing questions: $e");
      throw Exception("Failed to parse questions");
    }

    /// Form the GameObject
    GameObject game = GameObject(
      gameId: response.data["game_id"],
      questions: questions,
      userId: response.data["user_id"],
      generatedAt: response.data["generated_at"],
    );
    AppLogger.debug("question1: ${game.questions[0].toJson()}");
    AppLogger.debug(
      'Game started with ID: ${game.gameId} and ${game.questions.length} questions',
    );
    return Future.value(game);
  }

  Future<SubmitResponse> submitGameResult({required GameObject game}) async {
    String gameJson = jsonEncode(game);
    AppLogger.debug(gameJson);

    Response<dynamic> response = await apiService.submitGameResult(
      gameData: gameJson,
    );
    if (response.data is Map<String, dynamic> &&
        response.data.containsKey("ERROR")) {
      response.data = response.data["ERROR"];
    }
    AppLogger.debug('Game result submitted successfully');
    return SubmitResponse.fromJson(response.data);
  }

  Future<bool> flagQuestion({
    required String questionId,
    String? reason,
    String? notes,
  }) {
    final response = apiService.flagQuestion(
      questionId: questionId,
      userId: prefs.getString('userId'),
      reason: reason,
      notes: notes,
    );

    AppLogger.debug('Question flagged: success=$response, $questionId');
    return Future.value(response);
  }

  /// Uploads a file (either XFile or web bytes) and scans for wrong words
  Future<WrongWordEntry> checkHandwriteAnswer(
    String text, {
    XFile? imageFile,
    Uint8List? webImageBytes,
    required String gameId,
  }) async {
    try {
      // Upload the file
      Response uploadResponse;
      if (kIsWeb) {
        AppLogger.debug('Uploading file for web');
        uploadResponse = await apiService.uploadFileForWeb(
          webImageBytes: webImageBytes,
        );
      } else {
        AppLogger.debug('Uploading file for mobile');
        uploadResponse = await apiService.uploadFile(imageFile: imageFile);
      }

      if (uploadResponse.statusCode == 200 ||
          uploadResponse.statusCode == 201) {
        AppLogger.debug('File uploaded successfully');

        // Parse the upload response
        final fileUploadResponse = FileUploadResponse.fromJson(
          uploadResponse.data,
        );

        AppLogger.debug(
          'File upload response: ${fileUploadResponse.toString()}',
        );

        final storageBaseUrl = await AppConstants.storageBaseUrl;
        final checkHandwriteAnswerResponse = await apiService
            .checkHandwriteAnswer(
              imagePath: "$storageBaseUrl/${fileUploadResponse.storedFilename}",
              targetWord: text,
              gameId: gameId,
            );

        if (checkHandwriteAnswerResponse.statusCode == 200) {
          AppLogger.debug('Scanning for wrong words completed successfully');
          return WrongWordEntry.fromJson(checkHandwriteAnswerResponse.data);
        } else {
          AppLogger.error(
            'Failed to scan for wrong words: ${checkHandwriteAnswerResponse.statusCode}',
          );
          throw HttpExceptionFactory.fromStatusCode(
            checkHandwriteAnswerResponse.statusCode ?? 500,
            endpoint: '/user/wrong-words/scanning',
          );
        }
      } else {
        AppLogger.error('Failed to upload file: ${uploadResponse.statusCode}');
        throw HttpExceptionFactory.fromStatusCode(
          uploadResponse.statusCode ?? 500,
          endpoint: '/files/upload',
        );
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Network error during file upload or scanning: ${e.message}',
      );

      // Handle different types of network errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException('連線逾時，請檢查網路連線或稍後再試');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('網路連線錯誤，請檢查網路連線');
      } else if (e.response != null) {
        // Handle HTTP error responses
        throw HttpExceptionFactory.fromStatusCode(
          e.response!.statusCode ?? 500,
          endpoint: e.requestOptions.path,
        );
      } else {
        throw NetworkException('網路錯誤: ${e.message}');
      }
    } catch (e) {
      AppLogger.error('Unexpected error during file upload or scanning: $e');
      // Re-throw custom exceptions as-is
      if (e is HttpException || e is NetworkException) {
        rethrow;
      }
      throw Exception('上傳和掃描文件時發生未預期錯誤: $e');
    }
  }

  /// Helper method to handle DioException and convert to appropriate custom exceptions
  Never _handleDioException(DioException e, String endpoint) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw NetworkException('連線逾時，請檢查網路連線或稍後再試');
    } else if (e.type == DioExceptionType.connectionError) {
      throw NetworkException('網路連線錯誤，請檢查網路連線');
    } else if (e.response != null) {
      throw HttpExceptionFactory.fromStatusCode(
        e.response!.statusCode ?? 500,
        endpoint: endpoint,
      );
    } else {
      throw NetworkException('網路錯誤: ${e.message}');
    }
  }
}
