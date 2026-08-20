// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthResponseDtoImpl _$$AuthResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$AuthResponseDtoImpl(
  userId: json['userId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String,
  accessToken: json['accessToken'] as String,
  accessTokenExpiresAtUtc: DateTime.parse(
    json['accessTokenExpiresAtUtc'] as String,
  ),
  refreshToken: json['refreshToken'] as String,
  refreshTokenExpiresAtUtc: DateTime.parse(
    json['refreshTokenExpiresAtUtc'] as String,
  ),
);

Map<String, dynamic> _$$AuthResponseDtoImplToJson(
  _$AuthResponseDtoImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'accessToken': instance.accessToken,
  'accessTokenExpiresAtUtc': instance.accessTokenExpiresAtUtc.toIso8601String(),
  'refreshToken': instance.refreshToken,
  'refreshTokenExpiresAtUtc': instance.refreshTokenExpiresAtUtc
      .toIso8601String(),
};
