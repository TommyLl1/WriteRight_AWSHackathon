// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameObject {

 List<QuestionBase> get questions; int get generatedAt; String get userId; String get gameId;
/// Create a copy of GameObject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameObjectCopyWith<GameObject> get copyWith => _$GameObjectCopyWithImpl<GameObject>(this as GameObject, _$identity);

  /// Serializes this GameObject to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameObject&&const DeepCollectionEquality().equals(other.questions, questions)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.gameId, gameId) || other.gameId == gameId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(questions),generatedAt,userId,gameId);

@override
String toString() {
  return 'GameObject(questions: $questions, generatedAt: $generatedAt, userId: $userId, gameId: $gameId)';
}


}

/// @nodoc
abstract mixin class $GameObjectCopyWith<$Res>  {
  factory $GameObjectCopyWith(GameObject value, $Res Function(GameObject) _then) = _$GameObjectCopyWithImpl;
@useResult
$Res call({
 List<QuestionBase> questions, int generatedAt, String userId, String gameId
});




}
/// @nodoc
class _$GameObjectCopyWithImpl<$Res>
    implements $GameObjectCopyWith<$Res> {
  _$GameObjectCopyWithImpl(this._self, this._then);

  final GameObject _self;
  final $Res Function(GameObject) _then;

/// Create a copy of GameObject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questions = null,Object? generatedAt = null,Object? userId = null,Object? gameId = null,}) {
  return _then(_self.copyWith(
questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<QuestionBase>,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GameObject implements GameObject {
  const _GameObject({required final  List<QuestionBase> questions, required this.generatedAt, required this.userId, required this.gameId}): _questions = questions;
  factory _GameObject.fromJson(Map<String, dynamic> json) => _$GameObjectFromJson(json);

 final  List<QuestionBase> _questions;
@override List<QuestionBase> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}

@override final  int generatedAt;
@override final  String userId;
@override final  String gameId;

/// Create a copy of GameObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameObjectCopyWith<_GameObject> get copyWith => __$GameObjectCopyWithImpl<_GameObject>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameObjectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameObject&&const DeepCollectionEquality().equals(other._questions, _questions)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.gameId, gameId) || other.gameId == gameId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_questions),generatedAt,userId,gameId);

@override
String toString() {
  return 'GameObject(questions: $questions, generatedAt: $generatedAt, userId: $userId, gameId: $gameId)';
}


}

/// @nodoc
abstract mixin class _$GameObjectCopyWith<$Res> implements $GameObjectCopyWith<$Res> {
  factory _$GameObjectCopyWith(_GameObject value, $Res Function(_GameObject) _then) = __$GameObjectCopyWithImpl;
@override @useResult
$Res call({
 List<QuestionBase> questions, int generatedAt, String userId, String gameId
});




}
/// @nodoc
class __$GameObjectCopyWithImpl<$Res>
    implements _$GameObjectCopyWith<$Res> {
  __$GameObjectCopyWithImpl(this._self, this._then);

  final _GameObject _self;
  final $Res Function(_GameObject) _then;

/// Create a copy of GameObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questions = null,Object? generatedAt = null,Object? userId = null,Object? gameId = null,}) {
  return _then(_GameObject(
questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<QuestionBase>,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SubmitResponse {

 String get gameId; String get userId; int get totalScore; int get timeSpent; int get questionCount; int get earnedExp; int get remainingHearts; int get createdAt; int get correctCount;
/// Create a copy of SubmitResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmitResponseCopyWith<SubmitResponse> get copyWith => _$SubmitResponseCopyWithImpl<SubmitResponse>(this as SubmitResponse, _$identity);

  /// Serializes this SubmitResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmitResponse&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.totalScore, totalScore) || other.totalScore == totalScore)&&(identical(other.timeSpent, timeSpent) || other.timeSpent == timeSpent)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.earnedExp, earnedExp) || other.earnedExp == earnedExp)&&(identical(other.remainingHearts, remainingHearts) || other.remainingHearts == remainingHearts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.correctCount, correctCount) || other.correctCount == correctCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,userId,totalScore,timeSpent,questionCount,earnedExp,remainingHearts,createdAt,correctCount);

@override
String toString() {
  return 'SubmitResponse(gameId: $gameId, userId: $userId, totalScore: $totalScore, timeSpent: $timeSpent, questionCount: $questionCount, earnedExp: $earnedExp, remainingHearts: $remainingHearts, createdAt: $createdAt, correctCount: $correctCount)';
}


}

/// @nodoc
abstract mixin class $SubmitResponseCopyWith<$Res>  {
  factory $SubmitResponseCopyWith(SubmitResponse value, $Res Function(SubmitResponse) _then) = _$SubmitResponseCopyWithImpl;
@useResult
$Res call({
 String gameId, String userId, int totalScore, int timeSpent, int questionCount, int earnedExp, int remainingHearts, int createdAt, int correctCount
});




}
/// @nodoc
class _$SubmitResponseCopyWithImpl<$Res>
    implements $SubmitResponseCopyWith<$Res> {
  _$SubmitResponseCopyWithImpl(this._self, this._then);

  final SubmitResponse _self;
  final $Res Function(SubmitResponse) _then;

/// Create a copy of SubmitResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? userId = null,Object? totalScore = null,Object? timeSpent = null,Object? questionCount = null,Object? earnedExp = null,Object? remainingHearts = null,Object? createdAt = null,Object? correctCount = null,}) {
  return _then(_self.copyWith(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,totalScore: null == totalScore ? _self.totalScore : totalScore // ignore: cast_nullable_to_non_nullable
as int,timeSpent: null == timeSpent ? _self.timeSpent : timeSpent // ignore: cast_nullable_to_non_nullable
as int,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,earnedExp: null == earnedExp ? _self.earnedExp : earnedExp // ignore: cast_nullable_to_non_nullable
as int,remainingHearts: null == remainingHearts ? _self.remainingHearts : remainingHearts // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,correctCount: null == correctCount ? _self.correctCount : correctCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _SubmitResponse implements SubmitResponse {
  const _SubmitResponse({required this.gameId, required this.userId, required this.totalScore, required this.timeSpent, required this.questionCount, required this.earnedExp, required this.remainingHearts, required this.createdAt, required this.correctCount});
  factory _SubmitResponse.fromJson(Map<String, dynamic> json) => _$SubmitResponseFromJson(json);

@override final  String gameId;
@override final  String userId;
@override final  int totalScore;
@override final  int timeSpent;
@override final  int questionCount;
@override final  int earnedExp;
@override final  int remainingHearts;
@override final  int createdAt;
@override final  int correctCount;

/// Create a copy of SubmitResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubmitResponseCopyWith<_SubmitResponse> get copyWith => __$SubmitResponseCopyWithImpl<_SubmitResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubmitResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubmitResponse&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.totalScore, totalScore) || other.totalScore == totalScore)&&(identical(other.timeSpent, timeSpent) || other.timeSpent == timeSpent)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.earnedExp, earnedExp) || other.earnedExp == earnedExp)&&(identical(other.remainingHearts, remainingHearts) || other.remainingHearts == remainingHearts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.correctCount, correctCount) || other.correctCount == correctCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,userId,totalScore,timeSpent,questionCount,earnedExp,remainingHearts,createdAt,correctCount);

@override
String toString() {
  return 'SubmitResponse(gameId: $gameId, userId: $userId, totalScore: $totalScore, timeSpent: $timeSpent, questionCount: $questionCount, earnedExp: $earnedExp, remainingHearts: $remainingHearts, createdAt: $createdAt, correctCount: $correctCount)';
}


}

/// @nodoc
abstract mixin class _$SubmitResponseCopyWith<$Res> implements $SubmitResponseCopyWith<$Res> {
  factory _$SubmitResponseCopyWith(_SubmitResponse value, $Res Function(_SubmitResponse) _then) = __$SubmitResponseCopyWithImpl;
@override @useResult
$Res call({
 String gameId, String userId, int totalScore, int timeSpent, int questionCount, int earnedExp, int remainingHearts, int createdAt, int correctCount
});




}
/// @nodoc
class __$SubmitResponseCopyWithImpl<$Res>
    implements _$SubmitResponseCopyWith<$Res> {
  __$SubmitResponseCopyWithImpl(this._self, this._then);

  final _SubmitResponse _self;
  final $Res Function(_SubmitResponse) _then;

/// Create a copy of SubmitResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? userId = null,Object? totalScore = null,Object? timeSpent = null,Object? questionCount = null,Object? earnedExp = null,Object? remainingHearts = null,Object? createdAt = null,Object? correctCount = null,}) {
  return _then(_SubmitResponse(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,totalScore: null == totalScore ? _self.totalScore : totalScore // ignore: cast_nullable_to_non_nullable
as int,timeSpent: null == timeSpent ? _self.timeSpent : timeSpent // ignore: cast_nullable_to_non_nullable
as int,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,earnedExp: null == earnedExp ? _self.earnedExp : earnedExp // ignore: cast_nullable_to_non_nullable
as int,remainingHearts: null == remainingHearts ? _self.remainingHearts : remainingHearts // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,correctCount: null == correctCount ? _self.correctCount : correctCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WrongWordEntry {

 String get wrongImageUrl; String get correctChar; bool get isCorrect; String get reasoning; String get correctStrokeAnalysis; String get handwrittenStrokeAnalysis; String get comparisonAnalysis; String get improvementSuggestions;
/// Create a copy of WrongWordEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WrongWordEntryCopyWith<WrongWordEntry> get copyWith => _$WrongWordEntryCopyWithImpl<WrongWordEntry>(this as WrongWordEntry, _$identity);

  /// Serializes this WrongWordEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WrongWordEntry&&(identical(other.wrongImageUrl, wrongImageUrl) || other.wrongImageUrl == wrongImageUrl)&&(identical(other.correctChar, correctChar) || other.correctChar == correctChar)&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.correctStrokeAnalysis, correctStrokeAnalysis) || other.correctStrokeAnalysis == correctStrokeAnalysis)&&(identical(other.handwrittenStrokeAnalysis, handwrittenStrokeAnalysis) || other.handwrittenStrokeAnalysis == handwrittenStrokeAnalysis)&&(identical(other.comparisonAnalysis, comparisonAnalysis) || other.comparisonAnalysis == comparisonAnalysis)&&(identical(other.improvementSuggestions, improvementSuggestions) || other.improvementSuggestions == improvementSuggestions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wrongImageUrl,correctChar,isCorrect,reasoning,correctStrokeAnalysis,handwrittenStrokeAnalysis,comparisonAnalysis,improvementSuggestions);

@override
String toString() {
  return 'WrongWordEntry(wrongImageUrl: $wrongImageUrl, correctChar: $correctChar, isCorrect: $isCorrect, reasoning: $reasoning, correctStrokeAnalysis: $correctStrokeAnalysis, handwrittenStrokeAnalysis: $handwrittenStrokeAnalysis, comparisonAnalysis: $comparisonAnalysis, improvementSuggestions: $improvementSuggestions)';
}


}

/// @nodoc
abstract mixin class $WrongWordEntryCopyWith<$Res>  {
  factory $WrongWordEntryCopyWith(WrongWordEntry value, $Res Function(WrongWordEntry) _then) = _$WrongWordEntryCopyWithImpl;
@useResult
$Res call({
 String wrongImageUrl, String correctChar, bool isCorrect, String reasoning, String correctStrokeAnalysis, String handwrittenStrokeAnalysis, String comparisonAnalysis, String improvementSuggestions
});




}
/// @nodoc
class _$WrongWordEntryCopyWithImpl<$Res>
    implements $WrongWordEntryCopyWith<$Res> {
  _$WrongWordEntryCopyWithImpl(this._self, this._then);

  final WrongWordEntry _self;
  final $Res Function(WrongWordEntry) _then;

/// Create a copy of WrongWordEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wrongImageUrl = null,Object? correctChar = null,Object? isCorrect = null,Object? reasoning = null,Object? correctStrokeAnalysis = null,Object? handwrittenStrokeAnalysis = null,Object? comparisonAnalysis = null,Object? improvementSuggestions = null,}) {
  return _then(_self.copyWith(
wrongImageUrl: null == wrongImageUrl ? _self.wrongImageUrl : wrongImageUrl // ignore: cast_nullable_to_non_nullable
as String,correctChar: null == correctChar ? _self.correctChar : correctChar // ignore: cast_nullable_to_non_nullable
as String,isCorrect: null == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,correctStrokeAnalysis: null == correctStrokeAnalysis ? _self.correctStrokeAnalysis : correctStrokeAnalysis // ignore: cast_nullable_to_non_nullable
as String,handwrittenStrokeAnalysis: null == handwrittenStrokeAnalysis ? _self.handwrittenStrokeAnalysis : handwrittenStrokeAnalysis // ignore: cast_nullable_to_non_nullable
as String,comparisonAnalysis: null == comparisonAnalysis ? _self.comparisonAnalysis : comparisonAnalysis // ignore: cast_nullable_to_non_nullable
as String,improvementSuggestions: null == improvementSuggestions ? _self.improvementSuggestions : improvementSuggestions // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _WrongWordEntry implements WrongWordEntry {
  const _WrongWordEntry({required this.wrongImageUrl, required this.correctChar, required this.isCorrect, this.reasoning = "", this.correctStrokeAnalysis = "", this.handwrittenStrokeAnalysis = "", this.comparisonAnalysis = "", this.improvementSuggestions = ""});
  factory _WrongWordEntry.fromJson(Map<String, dynamic> json) => _$WrongWordEntryFromJson(json);

@override final  String wrongImageUrl;
@override final  String correctChar;
@override final  bool isCorrect;
@override@JsonKey() final  String reasoning;
@override@JsonKey() final  String correctStrokeAnalysis;
@override@JsonKey() final  String handwrittenStrokeAnalysis;
@override@JsonKey() final  String comparisonAnalysis;
@override@JsonKey() final  String improvementSuggestions;

/// Create a copy of WrongWordEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WrongWordEntryCopyWith<_WrongWordEntry> get copyWith => __$WrongWordEntryCopyWithImpl<_WrongWordEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WrongWordEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WrongWordEntry&&(identical(other.wrongImageUrl, wrongImageUrl) || other.wrongImageUrl == wrongImageUrl)&&(identical(other.correctChar, correctChar) || other.correctChar == correctChar)&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.correctStrokeAnalysis, correctStrokeAnalysis) || other.correctStrokeAnalysis == correctStrokeAnalysis)&&(identical(other.handwrittenStrokeAnalysis, handwrittenStrokeAnalysis) || other.handwrittenStrokeAnalysis == handwrittenStrokeAnalysis)&&(identical(other.comparisonAnalysis, comparisonAnalysis) || other.comparisonAnalysis == comparisonAnalysis)&&(identical(other.improvementSuggestions, improvementSuggestions) || other.improvementSuggestions == improvementSuggestions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wrongImageUrl,correctChar,isCorrect,reasoning,correctStrokeAnalysis,handwrittenStrokeAnalysis,comparisonAnalysis,improvementSuggestions);

@override
String toString() {
  return 'WrongWordEntry(wrongImageUrl: $wrongImageUrl, correctChar: $correctChar, isCorrect: $isCorrect, reasoning: $reasoning, correctStrokeAnalysis: $correctStrokeAnalysis, handwrittenStrokeAnalysis: $handwrittenStrokeAnalysis, comparisonAnalysis: $comparisonAnalysis, improvementSuggestions: $improvementSuggestions)';
}


}

/// @nodoc
abstract mixin class _$WrongWordEntryCopyWith<$Res> implements $WrongWordEntryCopyWith<$Res> {
  factory _$WrongWordEntryCopyWith(_WrongWordEntry value, $Res Function(_WrongWordEntry) _then) = __$WrongWordEntryCopyWithImpl;
@override @useResult
$Res call({
 String wrongImageUrl, String correctChar, bool isCorrect, String reasoning, String correctStrokeAnalysis, String handwrittenStrokeAnalysis, String comparisonAnalysis, String improvementSuggestions
});




}
/// @nodoc
class __$WrongWordEntryCopyWithImpl<$Res>
    implements _$WrongWordEntryCopyWith<$Res> {
  __$WrongWordEntryCopyWithImpl(this._self, this._then);

  final _WrongWordEntry _self;
  final $Res Function(_WrongWordEntry) _then;

/// Create a copy of WrongWordEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wrongImageUrl = null,Object? correctChar = null,Object? isCorrect = null,Object? reasoning = null,Object? correctStrokeAnalysis = null,Object? handwrittenStrokeAnalysis = null,Object? comparisonAnalysis = null,Object? improvementSuggestions = null,}) {
  return _then(_WrongWordEntry(
wrongImageUrl: null == wrongImageUrl ? _self.wrongImageUrl : wrongImageUrl // ignore: cast_nullable_to_non_nullable
as String,correctChar: null == correctChar ? _self.correctChar : correctChar // ignore: cast_nullable_to_non_nullable
as String,isCorrect: null == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,correctStrokeAnalysis: null == correctStrokeAnalysis ? _self.correctStrokeAnalysis : correctStrokeAnalysis // ignore: cast_nullable_to_non_nullable
as String,handwrittenStrokeAnalysis: null == handwrittenStrokeAnalysis ? _self.handwrittenStrokeAnalysis : handwrittenStrokeAnalysis // ignore: cast_nullable_to_non_nullable
as String,comparisonAnalysis: null == comparisonAnalysis ? _self.comparisonAnalysis : comparisonAnalysis // ignore: cast_nullable_to_non_nullable
as String,improvementSuggestions: null == improvementSuggestions ? _self.improvementSuggestions : improvementSuggestions // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
