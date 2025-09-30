import 'package:freezed_annotation/freezed_annotation.dart';
import 'questions.dart';

part 'game.freezed.dart';
part 'game.g.dart';

@freezed
abstract class GameObject with _$GameObject {
  const factory GameObject({
    required List<QuestionBase> questions,
    required int generatedAt,
    required String userId,
    required String gameId,
  }) = _GameObject;

  factory GameObject.fromJson(Map<String, dynamic> json) =>
      _$GameObjectFromJson(json);
}

// 
@freezed
abstract class SubmitResponse with _$SubmitResponse {
  const factory SubmitResponse({
    required String gameId,
    required String userId,
    required int totalScore,
    required int timeSpent,
    required int questionCount,
    required int earnedExp,
    required int remainingHearts,
    required int createdAt,
    required int correctCount,
  }) = _SubmitResponse;

  factory SubmitResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmitResponseFromJson(json);
}


@freezed
/// It is just called WrongWordEntry, it is actually the ai response
abstract class WrongWordEntry with _$WrongWordEntry {
  const factory WrongWordEntry({
    required String wrongImageUrl,
    required String correctChar,
    required bool isCorrect,
    @Default("") String reasoning,
    @Default("") String correctStrokeAnalysis,
    @Default("") String handwrittenStrokeAnalysis,
    @Default("") String comparisonAnalysis,
    @Default("") String improvementSuggestions,
  }) = _WrongWordEntry;

  factory WrongWordEntry.fromJson(Map<String, dynamic> json) =>
      _$WrongWordEntryFromJson(json);
}