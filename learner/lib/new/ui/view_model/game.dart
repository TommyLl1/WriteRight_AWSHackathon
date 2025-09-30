import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:writeright/new/data/models/game.dart';
import 'package:writeright/new/data/models/questions.dart';
import 'package:writeright/new/data/services/game_service.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/progress_bar.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';

class GameViewModel extends ChangeNotifier {
  final GameService gameService;

  /// Constructor
  GameViewModel({required this.gameService});

  /// Current game states
  Future<GameObject>? _gameObjectFuture; // Store the initialized Future
  GameObject? _gameObject; // Resolved game object
  int _currentQuestionIndex = 0;
  int _currentLives = 4;
  final int _maxLives = 4;
  bool _currentQuestionAnswered = false;
  List<bool?> _questionResults =
      []; // Track results: true=correct, false=incorrect, null=unanswered

  /// Public getters
  Future<GameObject>? get gameObjectFuture =>
      _gameObjectFuture; // Expose the future
  GameObject? get gameObject => _gameObject; // Expose the resolved object
  QuestionBase? get currentQuestion =>
      _gameObject?.questions[_currentQuestionIndex];
  bool get isGameStarted => _gameObject != null;
  int get currentLives => _currentLives;
  int get maxLives => _maxLives;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get totalQuestions => _gameObject?.questions.length ?? 0;
  List<bool?> get questionResults => _questionResults;
  bool get currentQuestionAnswered => _currentQuestionAnswered;
  bool get isLast =>
      _currentQuestionIndex >= (_gameObject?.questions.length ?? 0) - 1 ||
      _currentLives <= 0;
  bool get isCurrentAnswerCorrect {
    if (_gameObject == null || currentQuestion == null) return false;

    // Check if the current question is answered correctly
    if (currentQuestion is MultiChoiceQuestion) {
      return (currentQuestion as MultiChoiceQuestion).mcq.isCorrect;
    } else if (currentQuestion is HandwriteQuestion) {
      return (currentQuestion as HandwriteQuestion).writing.isCorrect ??
          false; // Handle null case
    } else if (currentQuestion is PairingCardsQuestion) {
      return (currentQuestion as PairingCardsQuestion).pairing.isCorrect;
    }
    return false; // Default case for unsupported question types
  }

  /// Submit button
  bool _isSubmitButtonActive = false;
  bool _isSubmitButtonLoading = false;
  bool _isSubmitError = false;

  /// Used by copy stroke question
  String _submitErrorMessage = '';

  /// Used by copy stroke question
  bool get isSubmitError => _isSubmitError;
  String get submitErrorMessage => _submitErrorMessage;
  bool get isSubmitButtonActive => _isSubmitButtonActive;
  bool get isSubmitButtonLoading => _isSubmitButtonLoading;
  set isSubmitButtonActive(bool value) {
    _isSubmitButtonActive = value;
    notifyListeners(); // Notify listeners when the button state changes
  }

  set isSubmitButtonLoading(bool value) {
    _isSubmitButtonLoading = value;
    notifyListeners(); // Notify listeners when the loading state changes
  }

  /// Popup states
  bool get isPopupVisible => currentQuestionAnswered;
  bool isPopupLoading = false;
  // Placeholder that is sutiable for every situation
  String popupMessage = '請點擊按鈕以繼續';

  /// Initialize the Future only once
  void initializeGame() {
    _gameObjectFuture = fetchGameObject();
  }

  /// Fetch the game object
  Future<GameObject> fetchGameObject() async {
    try {
      _gameObject = await gameService.startGame(qCount: 10); // Fetch the game
      // Initialize question results list
      _questionResults = List.filled(_gameObject!.questions.length, null);
      notifyListeners(); // Notify listeners after fetching
      return _gameObject!;
    } catch (e) {
      AppLogger.error('Error fetching game object: $e');
      rethrow; // Allow the error to propagate
    }
  }

  /// Three Types of Answers, all edit the current question, not sent to api
  void submitMcqAnswer(List<int> answer) {
    if (_gameObject != null) {
      // Update the current question with the selected answer
      if (currentQuestion is! MultiChoiceQuestion) {
        AppLogger.error('Current question is not a multiple choice question');
        return;
      }
      (currentQuestion as MultiChoiceQuestion).mcq.addAnswer = answer;
      _currentQuestionAnswered = true;
      AppLogger.debug(
        'Submitted answer: ${answer.join(', ')} for question index $_currentQuestionIndex',
      );
      // Track the result
      _questionResults[_currentQuestionIndex] = isCurrentAnswerCorrect;
      isCurrentAnswerCorrect ? null : _currentLives--;
      popupMessage = isCurrentAnswerCorrect ? '答對了!' : '加油! 再接再厲! ';
      notifyListeners();
    }
  }

  void submitHandwriteAnswer(List<Offset> strokes) async {
    _isSubmitError = false; // Reset error state
    _submitErrorMessage = ''; // Reset error message
    _isSubmitButtonLoading = true; // Set loading state
    notifyListeners();

    if (strokes.isEmpty) {
      AppLogger.error('No strokes provided for handwrite answer');
      _submitErrorMessage = '無法提交答案，請至少寫一筆。';
      _isSubmitError = true;
      _isSubmitButtonLoading = false; // Reset loading state
      notifyListeners();
      return;
    }

    if (currentQuestion != null) {
      // Update the current question with the written answer
      if (currentQuestion is! HandwriteQuestion) {
        AppLogger.error('Current question is not a writing question');
        return;
      }
      final targetChar =
          (currentQuestion as HandwriteQuestion).writing.handwriteTarget;
      final imageBytes = await _convertStrokesToImage(strokes);

      WrongWordEntry? response;
      try {
        response = await gameService.checkHandwriteAnswer(
          targetChar,
          imageFile: null, // No need to upload file, we use bytes
          webImageBytes: imageBytes,
          gameId: _gameObject!.gameId, // Pass the game ID
        );
      } catch (e) {
        AppLogger.error('Error checking handwrite answer: $e');
        _submitErrorMessage = '無法提交答案，請稍後再試。'; // Set error message for UI
        _isSubmitError = true; // Set error state
        _isSubmitButtonLoading = false; // Reset loading state
        notifyListeners();
        return;
      }

      (currentQuestion as HandwriteQuestion).writing.isCorrect =
          response.isCorrect;
      (currentQuestion as HandwriteQuestion).writing.submittedImage =
          response.wrongImageUrl;

      /// Optionally you can show other info to views, like the suggest correction
      _currentQuestionAnswered = true;

      AppLogger.debug(
        'Submitted handwrite answer: ${response.isCorrect} for question index $_currentQuestionIndex',
      );
      // Track the result
      _questionResults[_currentQuestionIndex] = isCurrentAnswerCorrect;
      isCurrentAnswerCorrect ? null : _currentLives--;
      popupMessage = isCurrentAnswerCorrect ? '答對了!' : '加油! 再接再厲! ';
      _isSubmitButtonLoading = false; // Reset loading state
      _isSubmitError = false; // Reset error state
      _submitErrorMessage = ''; // Reset error message
      notifyListeners();
    }
  }

  void submitPairingCardsAnswer(List<PairingOption> answer) {
    if (_gameObject != null) {
      // Update the current question with the selected answer
      if (currentQuestion is! PairingCardsQuestion) {
        AppLogger.error('Current question is not a pairing cards question');
        return;
      }
      (currentQuestion as PairingCardsQuestion).pairing.submittedPairs = answer;
      _currentQuestionAnswered = true;
      AppLogger.debug(
        'Submitted pairing cards answer: ${answer.map((e) => e.items.map((i) => i.text).join(', ')).join('; ')} for question index $_currentQuestionIndex',
      );
      // Track the result
      _questionResults[_currentQuestionIndex] = isCurrentAnswerCorrect;
      isCurrentAnswerCorrect ? null : _currentLives--;
      popupMessage = isCurrentAnswerCorrect ? '答對了!' : '加油! 再接再厲! ';
      notifyListeners();
    }
  }

  /// Move to the next question
  void handlePopupButtonPress(BuildContext context) {
    if (_gameObject == null) {
      AppLogger.error('Game object is null, cannot proceed to next question');
      return;
    }
    if (_currentLives <= 0) {
      AppLogger.debug('No lives left, ending game.');
      endGame(context);
      return;
    }
    if (isLast) {
      AppLogger.debug('Last question reached, ending game.');
      endGame(context);
      return;
    }

    _currentQuestionIndex++;
    _currentQuestionAnswered = false;
    notifyListeners();
  }

  /// Decrement lives on a wrong answer
  bool onWrongPair() {
    _currentLives--;
    notifyListeners();
    return _currentLives <= 0;
  }

  /// Check if there are more questions
  bool get hasMoreQuestions =>
      _currentQuestionIndex < (_gameObject?.questions.length ?? 0);

  /// Handle game over logic
  void endGame(BuildContext context) async {
    isPopupLoading = true;
    notifyListeners();
    try {
      SubmitResponse response = await gameService.submitGameResult(
        game: _gameObject!,
      );
      // Check if mounted
      if (context.mounted) {
        AppLogger.debug('Game result submitted successfully');
        context.go('/result', extra: response);
      }
    } catch (e) {
      AppLogger.error('Error submitting game result: $e');
      popupMessage = 'Error submitting game result. Please try again.';
    } finally {
      isPopupLoading = false;
      notifyListeners();
    }
  }

  /// Send the flag question request
  Future<bool> flagQuestion({
    required String questionId,
    String? reason,
    String? notes,
  }) async {
    if (currentQuestion == null) {
      AppLogger.error('No current question to flag');
      return false;
    }
    try {
      // Call the game service to flag the question
      bool success = await gameService.flagQuestion(
        questionId: questionId,
        reason: reason,
        notes: notes,
      );

      notifyListeners();
      return success;
    } catch (e) {
      AppLogger.error('Error flagging question: $e');
      popupMessage = 'Error flagging question. Please try again.';
      isPopupLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Convert question results to segment states for progress bar
  List<SegmentState> getProgressBarStates() {
    if (_gameObject == null) return [];

    return List.generate(totalQuestions, (index) {
      if (index < _questionResults.length) {
        final result = _questionResults[index];
        if (result == null) {
          // Not answered yet
          if (index == _currentQuestionIndex) {
            return SegmentState.current;
          } else {
            return SegmentState.pending;
          }
        } else if (result) {
          return SegmentState.completed;
        } else {
          return SegmentState.failed;
        }
      } else {
        // Beyond current results
        if (index == _currentQuestionIndex) {
          return SegmentState.current;
        } else {
          return SegmentState.pending;
        }
      }
    });
  }

  Future<Uint8List> _convertStrokesToImage(List<Offset> strokes) async {
    if (strokes.isEmpty) {
      throw ArgumentError('Strokes cannot be empty');
    }

    // Calculate the bounding box of the strokes
    double minX = strokes.map((e) => e.dx).reduce((a, b) => a < b ? a : b);
    double maxX = strokes.map((e) => e.dx).reduce((a, b) => a > b ? a : b);
    double minY = strokes.map((e) => e.dy).reduce((a, b) => a < b ? a : b);
    double maxY = strokes.map((e) => e.dy).reduce((a, b) => a > b ? a : b);

    // Add padding to ensure strokes are not clipped
    const double padding = 10.0;
    double canvasWidth = maxX - minX + padding * 2;
    double canvasHeight = maxY - minY + padding * 2;

    // Ensure the canvas size is at least 1x1
    canvasWidth = canvasWidth > 0 ? canvasWidth : 1.0;
    canvasHeight = canvasHeight > 0 ? canvasHeight : 1.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
    );

    // Draw strokes on the canvas
    final paint = Paint()
      ..color =
          const Color(0xFF000000) // Black color for strokes
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < strokes.length - 1; i++) {
      canvas.drawLine(
        strokes[i] - Offset(minX - padding, minY - padding),
        strokes[i + 1] - Offset(minX - padding, minY - padding),
        paint,
      );
    }

    // Convert canvas to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasWidth.toInt(),
      canvasHeight.toInt(),
    );

    // Encode image to PNG
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Ensure the image size is within 2 MiB
    const int maxSizeInBytes = 2 * 1024 * 1024; // 2 MiB
    if (pngBytes.lengthInBytes > maxSizeInBytes) {
      throw Exception('Generated image exceeds 2 MiB size limit');
    }

    return pngBytes;
  }
}
