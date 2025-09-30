// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wrong_words.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileUploadResponse {

 String get fileId; String get originalFilename; String get storedFilename; String get contentType; int get size; String get message;
/// Create a copy of FileUploadResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileUploadResponseCopyWith<FileUploadResponse> get copyWith => _$FileUploadResponseCopyWithImpl<FileUploadResponse>(this as FileUploadResponse, _$identity);

  /// Serializes this FileUploadResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileUploadResponse&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.storedFilename, storedFilename) || other.storedFilename == storedFilename)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.size, size) || other.size == size)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,originalFilename,storedFilename,contentType,size,message);

@override
String toString() {
  return 'FileUploadResponse(fileId: $fileId, originalFilename: $originalFilename, storedFilename: $storedFilename, contentType: $contentType, size: $size, message: $message)';
}


}

/// @nodoc
abstract mixin class $FileUploadResponseCopyWith<$Res>  {
  factory $FileUploadResponseCopyWith(FileUploadResponse value, $Res Function(FileUploadResponse) _then) = _$FileUploadResponseCopyWithImpl;
@useResult
$Res call({
 String fileId, String originalFilename, String storedFilename, String contentType, int size, String message
});




}
/// @nodoc
class _$FileUploadResponseCopyWithImpl<$Res>
    implements $FileUploadResponseCopyWith<$Res> {
  _$FileUploadResponseCopyWithImpl(this._self, this._then);

  final FileUploadResponse _self;
  final $Res Function(FileUploadResponse) _then;

/// Create a copy of FileUploadResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileId = null,Object? originalFilename = null,Object? storedFilename = null,Object? contentType = null,Object? size = null,Object? message = null,}) {
  return _then(_self.copyWith(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,originalFilename: null == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String,storedFilename: null == storedFilename ? _self.storedFilename : storedFilename // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _FileUploadResponse implements FileUploadResponse {
  const _FileUploadResponse({required this.fileId, required this.originalFilename, required this.storedFilename, required this.contentType, required this.size, required this.message});
  factory _FileUploadResponse.fromJson(Map<String, dynamic> json) => _$FileUploadResponseFromJson(json);

@override final  String fileId;
@override final  String originalFilename;
@override final  String storedFilename;
@override final  String contentType;
@override final  int size;
@override final  String message;

/// Create a copy of FileUploadResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileUploadResponseCopyWith<_FileUploadResponse> get copyWith => __$FileUploadResponseCopyWithImpl<_FileUploadResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileUploadResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileUploadResponse&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.storedFilename, storedFilename) || other.storedFilename == storedFilename)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.size, size) || other.size == size)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,originalFilename,storedFilename,contentType,size,message);

@override
String toString() {
  return 'FileUploadResponse(fileId: $fileId, originalFilename: $originalFilename, storedFilename: $storedFilename, contentType: $contentType, size: $size, message: $message)';
}


}

/// @nodoc
abstract mixin class _$FileUploadResponseCopyWith<$Res> implements $FileUploadResponseCopyWith<$Res> {
  factory _$FileUploadResponseCopyWith(_FileUploadResponse value, $Res Function(_FileUploadResponse) _then) = __$FileUploadResponseCopyWithImpl;
@override @useResult
$Res call({
 String fileId, String originalFilename, String storedFilename, String contentType, int size, String message
});




}
/// @nodoc
class __$FileUploadResponseCopyWithImpl<$Res>
    implements _$FileUploadResponseCopyWith<$Res> {
  __$FileUploadResponseCopyWithImpl(this._self, this._then);

  final _FileUploadResponse _self;
  final $Res Function(_FileUploadResponse) _then;

/// Create a copy of FileUploadResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileId = null,Object? originalFilename = null,Object? storedFilename = null,Object? contentType = null,Object? size = null,Object? message = null,}) {
  return _then(_FileUploadResponse(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,originalFilename: null == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String,storedFilename: null == storedFilename ? _self.storedFilename : storedFilename // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TextDetectionResponse {

 List<PastWrongWord>? get data; List<NonDBWrongWord>? get notFound;
/// Create a copy of TextDetectionResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextDetectionResponseCopyWith<TextDetectionResponse> get copyWith => _$TextDetectionResponseCopyWithImpl<TextDetectionResponse>(this as TextDetectionResponse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextDetectionResponse&&const DeepCollectionEquality().equals(other.data, data)&&const DeepCollectionEquality().equals(other.notFound, notFound));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data),const DeepCollectionEquality().hash(notFound));

@override
String toString() {
  return 'TextDetectionResponse(data: $data, notFound: $notFound)';
}


}

/// @nodoc
abstract mixin class $TextDetectionResponseCopyWith<$Res>  {
  factory $TextDetectionResponseCopyWith(TextDetectionResponse value, $Res Function(TextDetectionResponse) _then) = _$TextDetectionResponseCopyWithImpl;
@useResult
$Res call({
 List<PastWrongWord>? data, List<NonDBWrongWord>? notFound
});




}
/// @nodoc
class _$TextDetectionResponseCopyWithImpl<$Res>
    implements $TextDetectionResponseCopyWith<$Res> {
  _$TextDetectionResponseCopyWithImpl(this._self, this._then);

  final TextDetectionResponse _self;
  final $Res Function(TextDetectionResponse) _then;

/// Create a copy of TextDetectionResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = freezed,Object? notFound = freezed,}) {
  return _then(_self.copyWith(
data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<PastWrongWord>?,notFound: freezed == notFound ? _self.notFound : notFound // ignore: cast_nullable_to_non_nullable
as List<NonDBWrongWord>?,
  ));
}

}


/// @nodoc


class _TextDetectionResponse implements TextDetectionResponse {
  const _TextDetectionResponse({final  List<PastWrongWord>? data, final  List<NonDBWrongWord>? notFound}): _data = data,_notFound = notFound;
  

 final  List<PastWrongWord>? _data;
@override List<PastWrongWord>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<NonDBWrongWord>? _notFound;
@override List<NonDBWrongWord>? get notFound {
  final value = _notFound;
  if (value == null) return null;
  if (_notFound is EqualUnmodifiableListView) return _notFound;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of TextDetectionResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TextDetectionResponseCopyWith<_TextDetectionResponse> get copyWith => __$TextDetectionResponseCopyWithImpl<_TextDetectionResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TextDetectionResponse&&const DeepCollectionEquality().equals(other._data, _data)&&const DeepCollectionEquality().equals(other._notFound, _notFound));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data),const DeepCollectionEquality().hash(_notFound));

@override
String toString() {
  return 'TextDetectionResponse(data: $data, notFound: $notFound)';
}


}

/// @nodoc
abstract mixin class _$TextDetectionResponseCopyWith<$Res> implements $TextDetectionResponseCopyWith<$Res> {
  factory _$TextDetectionResponseCopyWith(_TextDetectionResponse value, $Res Function(_TextDetectionResponse) _then) = __$TextDetectionResponseCopyWithImpl;
@override @useResult
$Res call({
 List<PastWrongWord>? data, List<NonDBWrongWord>? notFound
});




}
/// @nodoc
class __$TextDetectionResponseCopyWithImpl<$Res>
    implements _$TextDetectionResponseCopyWith<$Res> {
  __$TextDetectionResponseCopyWithImpl(this._self, this._then);

  final _TextDetectionResponse _self;
  final $Res Function(_TextDetectionResponse) _then;

/// Create a copy of TextDetectionResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = freezed,Object? notFound = freezed,}) {
  return _then(_TextDetectionResponse(
data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<PastWrongWord>?,notFound: freezed == notFound ? _self._notFound : notFound // ignore: cast_nullable_to_non_nullable
as List<NonDBWrongWord>?,
  ));
}


}


/// @nodoc
mixin _$PastWrongWord {

 String get itemId; String get userId; int get wordId; int get wrongCount; String? get wrongImageUrl; int get lastWrongAt;
/// Create a copy of PastWrongWord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PastWrongWordCopyWith<PastWrongWord> get copyWith => _$PastWrongWordCopyWithImpl<PastWrongWord>(this as PastWrongWord, _$identity);

  /// Serializes this PastWrongWord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PastWrongWord&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.wordId, wordId) || other.wordId == wordId)&&(identical(other.wrongCount, wrongCount) || other.wrongCount == wrongCount)&&(identical(other.wrongImageUrl, wrongImageUrl) || other.wrongImageUrl == wrongImageUrl)&&(identical(other.lastWrongAt, lastWrongAt) || other.lastWrongAt == lastWrongAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,userId,wordId,wrongCount,wrongImageUrl,lastWrongAt);

@override
String toString() {
  return 'PastWrongWord(itemId: $itemId, userId: $userId, wordId: $wordId, wrongCount: $wrongCount, wrongImageUrl: $wrongImageUrl, lastWrongAt: $lastWrongAt)';
}


}

/// @nodoc
abstract mixin class $PastWrongWordCopyWith<$Res>  {
  factory $PastWrongWordCopyWith(PastWrongWord value, $Res Function(PastWrongWord) _then) = _$PastWrongWordCopyWithImpl;
@useResult
$Res call({
 String itemId, String userId, int wordId, int wrongCount, String? wrongImageUrl, int lastWrongAt
});




}
/// @nodoc
class _$PastWrongWordCopyWithImpl<$Res>
    implements $PastWrongWordCopyWith<$Res> {
  _$PastWrongWordCopyWithImpl(this._self, this._then);

  final PastWrongWord _self;
  final $Res Function(PastWrongWord) _then;

/// Create a copy of PastWrongWord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? userId = null,Object? wordId = null,Object? wrongCount = null,Object? wrongImageUrl = freezed,Object? lastWrongAt = null,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,wordId: null == wordId ? _self.wordId : wordId // ignore: cast_nullable_to_non_nullable
as int,wrongCount: null == wrongCount ? _self.wrongCount : wrongCount // ignore: cast_nullable_to_non_nullable
as int,wrongImageUrl: freezed == wrongImageUrl ? _self.wrongImageUrl : wrongImageUrl // ignore: cast_nullable_to_non_nullable
as String?,lastWrongAt: null == lastWrongAt ? _self.lastWrongAt : lastWrongAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PastWrongWord extends PastWrongWord {
  const _PastWrongWord({required this.itemId, required this.userId, required this.wordId, required this.wrongCount, this.wrongImageUrl, required this.lastWrongAt}): super._();
  factory _PastWrongWord.fromJson(Map<String, dynamic> json) => _$PastWrongWordFromJson(json);

@override final  String itemId;
@override final  String userId;
@override final  int wordId;
@override final  int wrongCount;
@override final  String? wrongImageUrl;
@override final  int lastWrongAt;

/// Create a copy of PastWrongWord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PastWrongWordCopyWith<_PastWrongWord> get copyWith => __$PastWrongWordCopyWithImpl<_PastWrongWord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PastWrongWordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PastWrongWord&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.wordId, wordId) || other.wordId == wordId)&&(identical(other.wrongCount, wrongCount) || other.wrongCount == wrongCount)&&(identical(other.wrongImageUrl, wrongImageUrl) || other.wrongImageUrl == wrongImageUrl)&&(identical(other.lastWrongAt, lastWrongAt) || other.lastWrongAt == lastWrongAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,userId,wordId,wrongCount,wrongImageUrl,lastWrongAt);

@override
String toString() {
  return 'PastWrongWord(itemId: $itemId, userId: $userId, wordId: $wordId, wrongCount: $wrongCount, wrongImageUrl: $wrongImageUrl, lastWrongAt: $lastWrongAt)';
}


}

/// @nodoc
abstract mixin class _$PastWrongWordCopyWith<$Res> implements $PastWrongWordCopyWith<$Res> {
  factory _$PastWrongWordCopyWith(_PastWrongWord value, $Res Function(_PastWrongWord) _then) = __$PastWrongWordCopyWithImpl;
@override @useResult
$Res call({
 String itemId, String userId, int wordId, int wrongCount, String? wrongImageUrl, int lastWrongAt
});




}
/// @nodoc
class __$PastWrongWordCopyWithImpl<$Res>
    implements _$PastWrongWordCopyWith<$Res> {
  __$PastWrongWordCopyWithImpl(this._self, this._then);

  final _PastWrongWord _self;
  final $Res Function(_PastWrongWord) _then;

/// Create a copy of PastWrongWord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? userId = null,Object? wordId = null,Object? wrongCount = null,Object? wrongImageUrl = freezed,Object? lastWrongAt = null,}) {
  return _then(_PastWrongWord(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,wordId: null == wordId ? _self.wordId : wordId // ignore: cast_nullable_to_non_nullable
as int,wrongCount: null == wrongCount ? _self.wrongCount : wrongCount // ignore: cast_nullable_to_non_nullable
as int,wrongImageUrl: freezed == wrongImageUrl ? _self.wrongImageUrl : wrongImageUrl // ignore: cast_nullable_to_non_nullable
as String?,lastWrongAt: null == lastWrongAt ? _self.lastWrongAt : lastWrongAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NonDBWrongWord {

 String? get wrongImageUrl; bool get isCorrect; String get reasoning; String get wrongChar;
/// Create a copy of NonDBWrongWord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NonDBWrongWordCopyWith<NonDBWrongWord> get copyWith => _$NonDBWrongWordCopyWithImpl<NonDBWrongWord>(this as NonDBWrongWord, _$identity);

  /// Serializes this NonDBWrongWord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NonDBWrongWord&&(identical(other.wrongImageUrl, wrongImageUrl) || other.wrongImageUrl == wrongImageUrl)&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.wrongChar, wrongChar) || other.wrongChar == wrongChar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wrongImageUrl,isCorrect,reasoning,wrongChar);

@override
String toString() {
  return 'NonDBWrongWord(wrongImageUrl: $wrongImageUrl, isCorrect: $isCorrect, reasoning: $reasoning, wrongChar: $wrongChar)';
}


}

/// @nodoc
abstract mixin class $NonDBWrongWordCopyWith<$Res>  {
  factory $NonDBWrongWordCopyWith(NonDBWrongWord value, $Res Function(NonDBWrongWord) _then) = _$NonDBWrongWordCopyWithImpl;
@useResult
$Res call({
 String? wrongImageUrl, bool isCorrect, String reasoning, String wrongChar
});




}
/// @nodoc
class _$NonDBWrongWordCopyWithImpl<$Res>
    implements $NonDBWrongWordCopyWith<$Res> {
  _$NonDBWrongWordCopyWithImpl(this._self, this._then);

  final NonDBWrongWord _self;
  final $Res Function(NonDBWrongWord) _then;

/// Create a copy of NonDBWrongWord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wrongImageUrl = freezed,Object? isCorrect = null,Object? reasoning = null,Object? wrongChar = null,}) {
  return _then(_self.copyWith(
wrongImageUrl: freezed == wrongImageUrl ? _self.wrongImageUrl : wrongImageUrl // ignore: cast_nullable_to_non_nullable
as String?,isCorrect: null == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,wrongChar: null == wrongChar ? _self.wrongChar : wrongChar // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _NonDBWrongWord extends NonDBWrongWord {
  const _NonDBWrongWord({this.wrongImageUrl, required this.isCorrect, required this.reasoning, required this.wrongChar}): super._();
  factory _NonDBWrongWord.fromJson(Map<String, dynamic> json) => _$NonDBWrongWordFromJson(json);

@override final  String? wrongImageUrl;
@override final  bool isCorrect;
@override final  String reasoning;
@override final  String wrongChar;

/// Create a copy of NonDBWrongWord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NonDBWrongWordCopyWith<_NonDBWrongWord> get copyWith => __$NonDBWrongWordCopyWithImpl<_NonDBWrongWord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NonDBWrongWordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NonDBWrongWord&&(identical(other.wrongImageUrl, wrongImageUrl) || other.wrongImageUrl == wrongImageUrl)&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.wrongChar, wrongChar) || other.wrongChar == wrongChar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wrongImageUrl,isCorrect,reasoning,wrongChar);

@override
String toString() {
  return 'NonDBWrongWord(wrongImageUrl: $wrongImageUrl, isCorrect: $isCorrect, reasoning: $reasoning, wrongChar: $wrongChar)';
}


}

/// @nodoc
abstract mixin class _$NonDBWrongWordCopyWith<$Res> implements $NonDBWrongWordCopyWith<$Res> {
  factory _$NonDBWrongWordCopyWith(_NonDBWrongWord value, $Res Function(_NonDBWrongWord) _then) = __$NonDBWrongWordCopyWithImpl;
@override @useResult
$Res call({
 String? wrongImageUrl, bool isCorrect, String reasoning, String wrongChar
});




}
/// @nodoc
class __$NonDBWrongWordCopyWithImpl<$Res>
    implements _$NonDBWrongWordCopyWith<$Res> {
  __$NonDBWrongWordCopyWithImpl(this._self, this._then);

  final _NonDBWrongWord _self;
  final $Res Function(_NonDBWrongWord) _then;

/// Create a copy of NonDBWrongWord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wrongImageUrl = freezed,Object? isCorrect = null,Object? reasoning = null,Object? wrongChar = null,}) {
  return _then(_NonDBWrongWord(
wrongImageUrl: freezed == wrongImageUrl ? _self.wrongImageUrl : wrongImageUrl // ignore: cast_nullable_to_non_nullable
as String?,isCorrect: null == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,wrongChar: null == wrongChar ? _self.wrongChar : wrongChar // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
