import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user.dart';

part 'auth_response_dto.freezed.dart';
part 'auth_response_dto.g.dart';

/// Exact wire format of Identity's successful login response.
@freezed
class AuthResponseDto with _$AuthResponseDto {
  const AuthResponseDto._();

  const factory AuthResponseDto({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String accessToken,
    required DateTime accessTokenExpiresAtUtc,
    required String refreshToken,
    required DateTime refreshTokenExpiresAtUtc,
  }) = _AuthResponseDto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);

  User toDomain() =>
      User(id: userId, email: email, fullName: '$firstName $lastName'.trim());
}
