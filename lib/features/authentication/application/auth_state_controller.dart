import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/session_events.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/entities/user.dart';
import 'auth_state.dart';
import 'providers.dart';

/// Owns the app-wide authentication state. Bridges use case results into a
/// simple [AuthState] that both screens and the GoRouter redirect logic
/// react to.
class AuthStateController extends Notifier<AuthState> {
  @override
  AuthState build() {
    SessionEvents.sessionExpiredTick.addListener(_handleSessionExpired);
    ref.onDispose(() {
      SessionEvents.sessionExpiredTick.removeListener(_handleSessionExpired);
    });
    _restoreSession();
    return const AuthState();
  }

  void _handleSessionExpired() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _restoreSession() async {
    _debugBootstrap('started');
    try {
      final repository = ref.read(authRepositoryProvider);
      final hasSession = await repository.hasActiveSession();
      if (!hasSession) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      _debugBootstrap('token exists');
      _debugBootstrap('calling /auth/me');
      final result = await ref.read(getCurrentUserUseCaseProvider).call();
      state = result.when(
        success: (user) {
          _debugBootstrap('/auth/me success');
          return AuthState(status: AuthStatus.authenticated, user: user);
        },
        failure: (failure) {
          _debugBootstrap('/auth/me failed: ${failure.runtimeType}');
          return const AuthState(status: AuthStatus.unauthenticated);
        },
      );
    } catch (error) {
      _debugBootstrap('/auth/me failed: ${error.runtimeType}');
      state = const AuthState(status: AuthStatus.unauthenticated);
    } finally {
      if (state.status == AuthStatus.unknown) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
      _debugBootstrap('final state: ${state.status.name}');
    }
  }

  void _debugBootstrap(String message) {
    if (kDebugMode) debugPrint('[AUTH_BOOTSTRAP] $message');
  }

  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(errorMessage: null);
    final result = await ref
        .read(loginUseCaseProvider)
        .call(email: email, password: password);
    return result.when(
      success: (user) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return LoginOutcome.success;
      },
      failure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        if (failure is ServerFailure &&
            failure.statusCode == 403 &&
            failure.errorCode == 'EMAIL_NOT_VERIFIED') {
          return LoginOutcome.emailNotVerified;
        }
        return LoginOutcome.failure;
      },
    );
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    state = state.copyWith(errorMessage: null);
    final result = await ref
        .read(registerUseCaseProvider)
        .call(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          phoneNumber: phoneNumber,
        );
    return result.when(
      success: (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return true;
      },
      failure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
    );
  }

  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider).call();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void replaceUser(User user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

final authStateControllerProvider =
    NotifierProvider<AuthStateController, AuthState>(AuthStateController.new);

enum LoginOutcome { success, emailNotVerified, failure }
