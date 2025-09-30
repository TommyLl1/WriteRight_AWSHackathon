// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrong_words.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileUploadResponse _$FileUploadResponseFromJson(Map<String, dynamic> json) =>
    _FileUploadResponse(
      fileId: json['file_id'] as String,
      originalFilename: json['original_filename'] as String,
      storedFilename: json['stored_filename'] as String,
      contentType: json['content_type'] as String,
      size: (json['size'] as num).toInt(),
      message: json['message'] as String,
    );

Map<String, dynamic> _$FileUploadResponseToJson(_FileUploadResponse instance) =>
    <String, dynamic>{
      'file_id': instance.fileId,
      'original_filename': instance.originalFilename,
      'stored_filename': instance.storedFilename,
      'content_type': instance.contentType,
      'size': instance.size,
      'message': instance.message,
    };

_PastWrongWord _$PastWrongWordFromJson(Map<String, dynamic> json) =>
    _PastWrongWord(
      itemId: json['item_id'] as String,
      userId: json['user_id'] as String,
      wordId: (json['word_id'] as num).toInt(),
      wrongCount: (json['wrong_count'] as num).toInt(),
      wrongImageUrl: json['wrong_image_url'] as String?,
      lastWrongAt: (json['last_wrong_at'] as num).toInt(),
    );

Map<String, dynamic> _$PastWrongWordToJson(_PastWrongWord instance) =>
    <String, dynamic>{
      'item_id': instance.itemId,
      'user_id': instance.userId,
      'word_id': instance.wordId,
      'wrong_count': instance.wrongCount,
      'wrong_image_url': instance.wrongImageUrl,
      'last_wrong_at': instance.lastWrongAt,
    };

_NonDBWrongWord _$NonDBWrongWordFromJson(Map<String, dynamic> json) =>
    _NonDBWrongWord(
      wrongImageUrl: json['wrong_image_url'] as String?,
      isCorrect: json['is_correct'] as bool,
      reasoning: json['reasoning'] as String,
      wrongChar: json['wrong_char'] as String,
    );

Map<String, dynamic> _$NonDBWrongWordToJson(_NonDBWrongWord instance) =>
    <String, dynamic>{
      'wrong_image_url': instance.wrongImageUrl,
      'is_correct': instance.isCorrect,
      'reasoning': instance.reasoning,
      'wrong_char': instance.wrongChar,
    };
