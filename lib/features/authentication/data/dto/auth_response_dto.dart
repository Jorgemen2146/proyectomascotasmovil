import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_dto.dart';

part 'auth_response_dto.freezed.dart';
part 'auth_response_dto.g.dart';

/// Wire-format response shared by the login, register and refresh
/// endpoints of the Identity service.
@freezed
class AuthResponseDto with _$AuthResponseDto {
  const factory AuthResponseDto({
    required String accessToken,
    required String refreshToken,
    required UserDto user,
  }) = _AuthResponseDto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);
}
