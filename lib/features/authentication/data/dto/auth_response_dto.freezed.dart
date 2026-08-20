// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AuthResponseDto _$AuthResponseDtoFromJson(Map<String, dynamic> json) {
  return _AuthResponseDto.fromJson(json);
}

/// @nodoc
mixin _$AuthResponseDto {
  String get userId => throw _privateConstructorUsedError;
  String get firstName => throw _privateConstructorUsedError;
  String get lastName => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get accessToken => throw _privateConstructorUsedError;
  DateTime get accessTokenExpiresAtUtc => throw _privateConstructorUsedError;
  String get refreshToken => throw _privateConstructorUsedError;
  DateTime get refreshTokenExpiresAtUtc => throw _privateConstructorUsedError;

  /// Serializes this AuthResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthResponseDtoCopyWith<AuthResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResponseDtoCopyWith<$Res> {
  factory $AuthResponseDtoCopyWith(
    AuthResponseDto value,
    $Res Function(AuthResponseDto) then,
  ) = _$AuthResponseDtoCopyWithImpl<$Res, AuthResponseDto>;
  @useResult
  $Res call({
    String userId,
    String firstName,
    String lastName,
    String email,
    String accessToken,
    DateTime accessTokenExpiresAtUtc,
    String refreshToken,
    DateTime refreshTokenExpiresAtUtc,
  });
}

/// @nodoc
class _$AuthResponseDtoCopyWithImpl<$Res, $Val extends AuthResponseDto>
    implements $AuthResponseDtoCopyWith<$Res> {
  _$AuthResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? email = null,
    Object? accessToken = null,
    Object? accessTokenExpiresAtUtc = null,
    Object? refreshToken = null,
    Object? refreshTokenExpiresAtUtc = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            accessTokenExpiresAtUtc: null == accessTokenExpiresAtUtc
                ? _value.accessTokenExpiresAtUtc
                : accessTokenExpiresAtUtc // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            refreshToken: null == refreshToken
                ? _value.refreshToken
                : refreshToken // ignore: cast_nullable_to_non_nullable
                      as String,
            refreshTokenExpiresAtUtc: null == refreshTokenExpiresAtUtc
                ? _value.refreshTokenExpiresAtUtc
                : refreshTokenExpiresAtUtc // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthResponseDtoImplCopyWith<$Res>
    implements $AuthResponseDtoCopyWith<$Res> {
  factory _$$AuthResponseDtoImplCopyWith(
    _$AuthResponseDtoImpl value,
    $Res Function(_$AuthResponseDtoImpl) then,
  ) = __$$AuthResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String firstName,
    String lastName,
    String email,
    String accessToken,
    DateTime accessTokenExpiresAtUtc,
    String refreshToken,
    DateTime refreshTokenExpiresAtUtc,
  });
}

/// @nodoc
class __$$AuthResponseDtoImplCopyWithImpl<$Res>
    extends _$AuthResponseDtoCopyWithImpl<$Res, _$AuthResponseDtoImpl>
    implements _$$AuthResponseDtoImplCopyWith<$Res> {
  __$$AuthResponseDtoImplCopyWithImpl(
    _$AuthResponseDtoImpl _value,
    $Res Function(_$AuthResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? email = null,
    Object? accessToken = null,
    Object? accessTokenExpiresAtUtc = null,
    Object? refreshToken = null,
    Object? refreshTokenExpiresAtUtc = null,
  }) {
    return _then(
      _$AuthResponseDtoImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        accessTokenExpiresAtUtc: null == accessTokenExpiresAtUtc
            ? _value.accessTokenExpiresAtUtc
            : accessTokenExpiresAtUtc // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        refreshToken: null == refreshToken
            ? _value.refreshToken
            : refreshToken // ignore: cast_nullable_to_non_nullable
                  as String,
        refreshTokenExpiresAtUtc: null == refreshTokenExpiresAtUtc
            ? _value.refreshTokenExpiresAtUtc
            : refreshTokenExpiresAtUtc // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthResponseDtoImpl extends _AuthResponseDto {
  const _$AuthResponseDtoImpl({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.accessToken,
    required this.accessTokenExpiresAtUtc,
    required this.refreshToken,
    required this.refreshTokenExpiresAtUtc,
  }) : super._();

  factory _$AuthResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthResponseDtoImplFromJson(json);

  @override
  final String userId;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final String email;
  @override
  final String accessToken;
  @override
  final DateTime accessTokenExpiresAtUtc;
  @override
  final String refreshToken;
  @override
  final DateTime refreshTokenExpiresAtUtc;

  @override
  String toString() {
    return 'AuthResponseDto(userId: $userId, firstName: $firstName, lastName: $lastName, email: $email, accessToken: $accessToken, accessTokenExpiresAtUtc: $accessTokenExpiresAtUtc, refreshToken: $refreshToken, refreshTokenExpiresAtUtc: $refreshTokenExpiresAtUtc)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResponseDtoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(
                  other.accessTokenExpiresAtUtc,
                  accessTokenExpiresAtUtc,
                ) ||
                other.accessTokenExpiresAtUtc == accessTokenExpiresAtUtc) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            (identical(
                  other.refreshTokenExpiresAtUtc,
                  refreshTokenExpiresAtUtc,
                ) ||
                other.refreshTokenExpiresAtUtc == refreshTokenExpiresAtUtc));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    firstName,
    lastName,
    email,
    accessToken,
    accessTokenExpiresAtUtc,
    refreshToken,
    refreshTokenExpiresAtUtc,
  );

  /// Create a copy of AuthResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResponseDtoImplCopyWith<_$AuthResponseDtoImpl> get copyWith =>
      __$$AuthResponseDtoImplCopyWithImpl<_$AuthResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthResponseDtoImplToJson(this);
  }
}

abstract class _AuthResponseDto extends AuthResponseDto {
  const factory _AuthResponseDto({
    required final String userId,
    required final String firstName,
    required final String lastName,
    required final String email,
    required final String accessToken,
    required final DateTime accessTokenExpiresAtUtc,
    required final String refreshToken,
    required final DateTime refreshTokenExpiresAtUtc,
  }) = _$AuthResponseDtoImpl;
  const _AuthResponseDto._() : super._();

  factory _AuthResponseDto.fromJson(Map<String, dynamic> json) =
      _$AuthResponseDtoImpl.fromJson;

  @override
  String get userId;
  @override
  String get firstName;
  @override
  String get lastName;
  @override
  String get email;
  @override
  String get accessToken;
  @override
  DateTime get accessTokenExpiresAtUtc;
  @override
  String get refreshToken;
  @override
  DateTime get refreshTokenExpiresAtUtc;

  /// Create a copy of AuthResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthResponseDtoImplCopyWith<_$AuthResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
