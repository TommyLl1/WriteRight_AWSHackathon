import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String userId,
    required String email,
    required String name,
    required int level,
    required int exp,
    required int createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// @freezed
// abstract class LoginRequest with _$LoginRequest {
//   const factory LoginRequest({
//     required String email,
//     required String password,
//   }) = _LoginRequest;

//   factory LoginRequest.fromJson(Map<String, dynamic> json) =>
//       _$LoginRequestFromJson(json);
// }