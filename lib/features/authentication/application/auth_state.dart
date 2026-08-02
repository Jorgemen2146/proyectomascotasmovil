import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/entities/user.dart';

part 'auth_state.freezed.dart';

/// High-level authentication lifecycle status, driving GoRouter redirects.
enum AuthStatus {
  /// Initial state: session validity not yet determined.
  unknown,
  authenticated,
  unauthenticated,
}

/// Immutable state exposed by [AuthStateController] to the presentation
/// layer (screens) and the router's redirect logic.
@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.unknown) AuthStatus status,
    User? user,
    String? errorMessage,
  }) = _AuthState;
}
