import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// Wire-format representation of a user, as returned by the Identity
/// service. Kept separate from [User] so backend field renames never leak
/// into the domain layer.
@freezed
class UserDto with _$UserDto {
  const UserDto._();

  const factory UserDto({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? profilePhotoUrl,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  User toDomain() => User(
    id: userId,
    email: email,
    fullName: '$firstName $lastName'.trim(),
    phoneNumber: phoneNumber,
    profilePhotoUrl: profilePhotoUrl,
  );
}
