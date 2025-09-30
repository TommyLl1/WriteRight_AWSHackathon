import 'dart:core';
import 'package:dio/dio.dart';
import 'package:writeright/new/utils/constants.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/utils/exceptions.dart';
import 'package:writeright/new/data/api_service.dart';
import 'package:writeright/new/data/models/wrong_character.dart';
import 'package:writeright/new/data/models/wrong_words.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

/// Service for managing wrong characters using the actual API
class WrongCharacterService {
  // Dependency
  final ApiService apiService;
  WrongCharacterService(this.apiService);

  /// Searches for wrong characters based on query with pagination
  Future<WrongCharacterResponse> searchCharacters(
    String query, {
    int page = 1,
    int pageSize = 100,
    String? userId,
  }) async {
    try {
      AppLogger.debug(
        'Searching wrong characters with query: "$query", page: $page, pageSize: $pageSize',
      );

      // Get all wrong words first, then filter locally
      // The API doesn't seem to support search, so we'll implement client-side filtering
      final response = await apiService.getUserWrongWords(
        userId: userId,
        page: page,
        pageSize: pageSize,
      );

      if (response.statusCode == 200) {
        final wrongCharacterResponse = WrongCharacterResponse.fromJson(
          response.data,
        );

        // If no query, return all results
        if (query.isEmpty) {
          AppLogger.debug(
            'No search query, returning all ${wrongCharacterResponse.items.length} characters',
          );
          return wrongCharacterResponse;
        }

        // Filter and rank results based on query relevance
        final filteredWithRelevance = wrongCharacterResponse.items
            .map((character) {
              int relevanceScore = _calculateRelevanceScore(character, query);
              return MapEntry(character, relevanceScore);
            })
            .where((entry) => entry.value > 0) // Only include matches
            .toList();

        // Sort by relevance score (higher is better)
        filteredWithRelevance.sort((a, b) => b.value.compareTo(a.value));

        final filtered = filteredWithRelevance
            .map((entry) => entry.key)
            .toList();

        AppLogger.debug(
          'Filtered ${filtered.length} characters from ${wrongCharacterResponse.items.length} total, ranked by relevance',
        );

        return WrongCharacterResponse(
          items: filtered,
          page: page,
          pageSize: pageSize,
          count: filtered.length,
        );
      } else {
        AppLogger.error('Failed to search characters: ${response.statusCode}');
        throw HttpExceptionFactory.fromStatusCode(
          response.statusCode ?? 500,
          endpoint: '/user/wrong-words',
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Network error while searching characters: ${e.message}');
      _handleDioException(e, '/user/wrong-words');
    } catch (e) {
      AppLogger.error('Unexpected error while searching characters: $e');
      if (e is HttpException || e is NetworkException) {
        rethrow;
      }
      throw Exception('搜尋錯字時發生未預期錯誤: $e');
    }
  }

  /// Gets all wrong characters with pagination
  Future<WrongCharacterResponse> getAllCharacters({
    int page = 1,
    int pageSize = 100,
    String? userId,
  }) async {
    try {
      AppLogger.debug(
        'Getting all wrong characters, page: $page, pageSize: $pageSize',
      );

      final response = await apiService.getUserWrongWords(
        userId: userId,
        page: page,
        pageSize: pageSize,
      );

      if (response.statusCode == 200) {
        final wrongCharacterResponse = WrongCharacterResponse.fromJson(
          response.data,
        );
        AppLogger.debug(
          'Retrieved ${wrongCharacterResponse.items.length} wrong characters',
        );
        return wrongCharacterResponse;
      } else {
        AppLogger.error('Failed to get characters: ${response.statusCode}');
        throw HttpExceptionFactory.fromStatusCode(
          response.statusCode ?? 500,
          endpoint: '/user/wrong-words',
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Network error while getting characters: ${e.message}');
      _handleDioException(e, '/user/wrong-words');
    } catch (e) {
      AppLogger.error('Unexpected error while getting characters: $e');
      if (e is HttpException || e is NetworkException) {
        rethrow;
      }
      throw Exception('獲取錯字資料時發生未預期錯誤: $e');
    }
  }

  /// Loads all wrong characters at once (no pagination)
  Future<List<WrongCharacter>> loadAllCharacters({String? userId}) async {
    try {
      AppLogger.debug('Loading all characters without pagination');

      final response = await apiService.getUserWrongWords(
        userId: userId,
        noPaging: true,
      );

      if (response.statusCode == 200) {
        final wrongCharacterResponse = WrongCharacterResponse.fromJson(
          response.data,
        );
        AppLogger.debug(
          'Loaded ${wrongCharacterResponse.items.length} characters without pagination',
        );
        return wrongCharacterResponse.items;
      } else {
        AppLogger.error(
          'Failed to load all characters: ${response.statusCode}',
        );
        throw HttpExceptionFactory.fromStatusCode(
          response.statusCode ?? 500,
          endpoint: '/user/wrong-words',
        );
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Network error while loading all characters: ${e.message}',
      );
      _handleDioException(e, '/user/wrong-words');
    } catch (e) {
      AppLogger.error('Unexpected error while loading all characters: $e');
      if (e is HttpException || e is NetworkException) {
        rethrow;
      }
      throw Exception('載入所有錯字資料時發生未預期錯誤: $e');
    }
  }

  /// Gets a specific character by its ID
  /// Note: The API doesn't have a specific endpoint for this, so we'll get all and filter
  Future<WrongCharacter?> getCharacterById(int wordId) async {
    try {
      AppLogger.debug('Getting character by ID: $wordId');

      // Since there's no specific endpoint, get all characters and find the one we need
      final allCharacters = await loadAllCharacters();

      try {
        final character = allCharacters.firstWhere(
          (character) => character.wordId == wordId,
        );
        AppLogger.debug(
          'Found character with ID $wordId: ${character.character}',
        );
        return character;
      } catch (e) {
        AppLogger.debug('Character with ID $wordId not found');
        return null;
      }
    } catch (e) {
      AppLogger.error('Error getting character by ID $wordId: $e');
      return null;
    }
  }

  /// Gets a specific character by its text
  /// Note: The API doesn't have a specific endpoint for this, so we'll get all and filter
  Future<WrongCharacter?> getCharacterByText(String characterText) async {
    try {
      AppLogger.debug('Getting character by text: $characterText');

      // Since there's no specific endpoint, get all characters and find the one we need
      final allCharacters = await loadAllCharacters();

      try {
        final character = allCharacters.firstWhere(
          (character) => character.character == characterText,
        );
        AppLogger.debug('Found character: $characterText');
        return character;
      } catch (e) {
        AppLogger.debug('Character "$characterText" not found');
        return null;
      }
    } catch (e) {
      AppLogger.error('Error getting character by text "$characterText": $e');
      return null;
    }
  }

  /// Adds a new wrong word to the user's collection
  Future<bool> addWrongWord(String word, {String? userId}) async {
    try {
      AppLogger.debug('Adding wrong word: $word');

      final response = await apiService.addWrongWord(
        userId: userId,
        word: word,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.debug('Successfully added wrong word: $word');
        return true;
      } else {
        AppLogger.error('Failed to add wrong word: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      AppLogger.error('Network error while adding wrong word: ${e.message}');
      _handleDioException(e, '/user/wrong-words');
    } catch (e) {
      AppLogger.error('Unexpected error while adding wrong word: $e');
      if (e is HttpException || e is NetworkException) {
        rethrow;
      }
      throw Exception('新增錯字時發生未預期錯誤: $e');
    }
  }

  /// Gets the total count of wrong words for the user using the API endpoint
  Future<int> getTotalCount({String? userId}) async {
    try {
      final resp = await apiService.getUserWrongWordCount(userId);
      AppLogger.debug(
        'WrongCharacterService.getTotalCount response: ${resp.statusCode}; data: ${resp.data}',
      );
      if (resp.statusCode == 200 && resp.data != null) {
        return resp.data as int;
      }

      throw HttpExceptionFactory.fromStatusCode(
        resp.statusCode ?? 500,
        endpoint: '/user/wrong-words/count',
      );
    } on DioException catch (e) {
      AppLogger.error('Network error while getting total count: ${e.message}');
      _handleDioException(e, '/user/wrong-words/count');
    } catch (e) {
      AppLogger.error('Unexpected error while getting total count: $e');
      if (e is HttpException || e is NetworkException) {
        rethrow;
      }
      throw Exception('獲取錯字總數時發生未預期錯誤: $e');
    }
  }

  /// Uploads a file (either XFile or web bytes) and scans for wrong words
  Future<TextDetectionResponse> uploadAndScan({
    XFile? imageFile,
    Uint8List? webImageBytes,
    String? description,
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

      if (uploadResponse.statusCode != 200 &&
          uploadResponse.statusCode != 201) {
        AppLogger.error('Failed to upload file: ${uploadResponse.statusCode}');
        throw HttpExceptionFactory.fromStatusCode(
          uploadResponse.statusCode ?? 500,
          endpoint: '/files/upload',
        );
      }
      AppLogger.debug('File uploaded successfully');

      // Parse the upload response
      final fileUploadResponse = FileUploadResponse.fromJson(
        uploadResponse.data,
      );

      AppLogger.debug('File upload response: ${fileUploadResponse.toString()}');

      // Notify the backend to scan for wrong words
      final storageBaseUrl = await AppConstants.storageBaseUrl;
      final scanningResponse = await apiService.scanningWrongWords(
        uploadedUrl: "$storageBaseUrl/${fileUploadResponse.storedFilename}",
      );

      if (scanningResponse.statusCode == 200) {
        AppLogger.debug('Scanning for wrong words completed successfully');

        return TextDetectionResponse.fromJson(scanningResponse.data);
      }
      // Handle non-200 responses
      AppLogger.error(
        'Failed to scan for wrong words: ${scanningResponse.statusCode}',
      );
      throw HttpExceptionFactory.fromStatusCode(
        scanningResponse.statusCode ?? 500,
        endpoint: '/user/wrong-words/scanning',
      );
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

  /// Calculates relevance score based on which field matches the query
  /// Higher scores indicate higher relevance:
  /// character: 100, correctWriting: 80, pronunciation: 60, meaning: 40, description: 20
  int _calculateRelevanceScore(WrongCharacter character, String query) {
    final queryLower = query.toLowerCase();

    // Check character field (highest priority)
    if (character.character.contains(query)) {
      return 100;
    }

    // Check correctWriting field
    if (character.correctWriting.contains(query)) {
      return 80;
    }

    // Check pronunciation field (case-insensitive)
    if (character.pronunciation.toLowerCase().contains(queryLower)) {
      return 60;
    }

    // Check meaning field
    if (character.meaning.contains(query)) {
      return 40;
    }

    // Check description field (lowest priority)
    if (character.description?.contains(query) ?? false) {
      return 20;
    }

    // No match found
    return 0;
  }
}
