import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// Core domain entity representing an authenticated user. Contains only
/// what the app needs to display/reason about — never raw backend DTO
/// fields.
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String fullName,
    String? phoneNumber,
    String? profilePhotoUrl,
  }) = _User;
}
