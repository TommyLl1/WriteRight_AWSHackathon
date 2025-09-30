import 'package:freezed_annotation/freezed_annotation.dart';

part 'wrong_words.freezed.dart';
part 'wrong_words.g.dart';

@freezed
abstract class FileUploadResponse with _$FileUploadResponse {
  const factory FileUploadResponse({
    required String fileId,
    required String originalFilename,
    required String storedFilename,
    required String contentType,
    required int size,
    required String message,
  }) = _FileUploadResponse;

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$FileUploadResponseFromJson(json);
}

@freezed
abstract class TextDetectionResponse with _$TextDetectionResponse {
  const factory TextDetectionResponse({
    List<PastWrongWord>? data,
    List<NonDBWrongWord>? notFound,
  }) = _TextDetectionResponse;

  factory TextDetectionResponse.fromJson(Map<String, dynamic> json) {
    List<NonDBWrongWord>? notFoundList;

    if (json['not_found'] != null) {
      final notFoundMap = json['not_found'] as Map<String, dynamic>;
      notFoundList = notFoundMap.entries
          .map(
            (entry) => NonDBWrongWord(
              wrongChar: entry.key,
              wrongImageUrl: entry.value as String?,
              isCorrect: false,
              reasoning: "資料庫中沒有這個字",
            ),
          )
          .toList();
    }

    return TextDetectionResponse(
      data: json['data'] != null
          ? (json['data'] as List)
                .map((item) => PastWrongWord.fromJson(item))
                .toList()
          : null,
      notFound: notFoundList,
    );
  }
}

@freezed
abstract class PastWrongWord
    with _$PastWrongWord
    implements WrongWordDisplayable {
  const factory PastWrongWord({
    required String itemId,
    required String userId,
    required int wordId,
    required int wrongCount,
    String? wrongImageUrl,
    required int lastWrongAt,
  }) = _PastWrongWord;

  const PastWrongWord._();

  factory PastWrongWord.fromJson(Map<String, dynamic> json) =>
      _$PastWrongWordFromJson(json);

  @override
  String get displayCharacter => String.fromCharCode(wordId);

  @override
  bool get isInDatabase => true;

  @override
  String get reasoning => "錯誤次數: $wrongCount";

  @override
  bool get isCorrect => false;
}

@freezed
abstract class NonDBWrongWord
    with _$NonDBWrongWord
    implements WrongWordDisplayable {
  const factory NonDBWrongWord({
    String? wrongImageUrl,
    required bool isCorrect,
    required String reasoning,
    required String wrongChar,
  }) = _NonDBWrongWord;

  const NonDBWrongWord._();

  factory NonDBWrongWord.fromJson(Map<String, dynamic> json) =>
      _$NonDBWrongWordFromJson(json);

  @override
  String get displayCharacter => wrongChar;

  @override
  bool get isInDatabase => false;

  @override
  int? get wrongCount => null;
}

// Base interface for wrong word display
abstract class WrongWordDisplayable {
  String? get wrongImageUrl;
  String get displayCharacter;
  int? get wrongCount;
  bool get isInDatabase;
  String? get reasoning;
  bool get isCorrect;
}
