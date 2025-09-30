// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  userId: json['user_id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  level: (json['level'] as num).toInt(),
  exp: (json['exp'] as num).toInt(),
  createdAt: (json['created_at'] as num).toInt(),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'user_id': instance.userId,
  'email': instance.email,
  'name': instance.name,
  'level': instance.level,
  'exp': instance.exp,
  'created_at': instance.createdAt,
};
