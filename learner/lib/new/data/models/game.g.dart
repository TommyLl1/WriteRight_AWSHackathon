// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameObject _$GameObjectFromJson(Map<String, dynamic> json) => _GameObject(
  questions: (json['questions'] as List<dynamic>)
      .map((e) => QuestionBase.fromJson(e as Map<String, dynamic>))
      .toList(),
  generatedAt: (json['generated_at'] as num).toInt(),
  userId: json['user_id'] as String,
  gameId: json['game_id'] as String,
);

Map<String, dynamic> _$GameObjectToJson(_GameObject instance) =>
    <String, dynamic>{
      'questions': instance.questions,
      'generated_at': instance.generatedAt,
      'user_id': instance.userId,
      'game_id': instance.gameId,
    };

_SubmitResponse _$SubmitResponseFromJson(Map<String, dynamic> json) =>
    _SubmitResponse(
      gameId: json['game_id'] as String,
      userId: json['user_id'] as String,
      totalScore: (json['total_score'] as num).toInt(),
      timeSpent: (json['time_spent'] as num).toInt(),
      questionCount: (json['question_count'] as num).toInt(),
      earnedExp: (json['earned_exp'] as num).toInt(),
      remainingHearts: (json['remaining_hearts'] as num).toInt(),
      createdAt: (json['created_at'] as num).toInt(),
      correctCount: (json['correct_count'] as num).toInt(),
    );

Map<String, dynamic> _$SubmitResponseToJson(_SubmitResponse instance) =>
    <String, dynamic>{
      'game_id': instance.gameId,
      'user_id': instance.userId,
      'total_score': instance.totalScore,
      'time_spent': instance.timeSpent,
      'question_count': instance.questionCount,
      'earned_exp': instance.earnedExp,
      'remaining_hearts': instance.remainingHearts,
      'created_at': instance.createdAt,
      'correct_count': instance.correctCount,
    };

_WrongWordEntry _$WrongWordEntryFromJson(Map<String, dynamic> json) =>
    _WrongWordEntry(
      wrongImageUrl: json['wrong_image_url'] as String,
      correctChar: json['correct_char'] as String,
      isCorrect: json['is_correct'] as bool,
      reasoning: json['reasoning'] as String? ?? "",
      correctStrokeAnalysis: json['correct_stroke_analysis'] as String? ?? "",
      handwrittenStrokeAnalysis:
          json['handwritten_stroke_analysis'] as String? ?? "",
      comparisonAnalysis: json['comparison_analysis'] as String? ?? "",
      improvementSuggestions: json['improvement_suggestions'] as String? ?? "",
    );

Map<String, dynamic> _$WrongWordEntryToJson(_WrongWordEntry instance) =>
    <String, dynamic>{
      'wrong_image_url': instance.wrongImageUrl,
      'correct_char': instance.correctChar,
      'is_correct': instance.isCorrect,
      'reasoning': instance.reasoning,
      'correct_stroke_analysis': instance.correctStrokeAnalysis,
      'handwritten_stroke_analysis': instance.handwrittenStrokeAnalysis,
      'comparison_analysis': instance.comparisonAnalysis,
      'improvement_suggestions': instance.improvementSuggestions,
    };
