import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/auth_repository.dart';
import 'providers.dart';

enum PasswordRecoveryStep { email, code, password, success }

class PasswordRecoveryState {
  const PasswordRecoveryState({
    this.email = '',
    this.code = '',
    this.step = PasswordRecoveryStep.email,
    this.requestingCode = false,
    this.verifyingCode = false,
    this.resettingPassword = false,
    this.message,
    this.error,
  });

  final String email;
  final String code;
  final PasswordRecoveryStep step;
  final bool requestingCode;
  final bool verifyingCode;
  final bool resettingPassword;
  final String? message;
  final String? error;

  bool get isBusy => requestingCode || verifyingCode || resettingPassword;

  PasswordRecoveryState copyWith({
    String? email,
    String? code,
    PasswordRecoveryStep? step,
    bool? requestingCode,
    bool? verifyingCode,
    bool? resettingPassword,
    String? message,
    String? error,
    bool clearMessage = false,
    bool clearError = false,
  }) => PasswordRecoveryState(
    email: email ?? this.email,
    code: code ?? this.code,
    step: step ?? this.step,
    requestingCode: requestingCode ?? this.requestingCode,
    verifyingCode: verifyingCode ?? this.verifyingCode,
    resettingPassword: resettingPassword ?? this.resettingPassword,
    message: clearMessage ? null : message ?? this.message,
    error: clearError ? null : error ?? this.error,
  );
}

class PasswordRecoveryController
    extends AutoDisposeNotifier<PasswordRecoveryState> {
  bool _disposed = false;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  PasswordRecoveryState build() {
    ref.onDispose(() => _disposed = true);
    return const PasswordRecoveryState();
  }

  Future<bool> requestCode(String email) async {
    if (state.isBusy) return false;
    final normalizedEmail = email.trim();
    state = state.copyWith(
      email: normalizedEmail,
      code: '',
      requestingCode: true,
      clearError: true,
      clearMessage: true,
    );
    final result = await _repository.forgotPassword(email: normalizedEmail);
    if (_disposed) return false;
    return result.when(
      success: (message) {
        state = state.copyWith(
          requestingCode: false,
          step: PasswordRecoveryStep.code,
          message: message,
          clearError: true,
        );
        return true;
      },
      failure: (failure) {
        state = state.copyWith(requestingCode: false, error: failure.message);
        return false;
      },
    );
  }

  Future<bool> resendCode() async {
    if (state.email.isEmpty || state.isBusy) return false;
    state = state.copyWith(
      code: '',
      requestingCode: true,
      clearError: true,
      clearMessage: true,
    );
    final result = await _repository.forgotPassword(email: state.email);
    if (_disposed) return false;
    return result.when(
      success: (message) {
        state = state.copyWith(
          requestingCode: false,
          message: message,
          clearError: true,
        );
        return true;
      },
      failure: (failure) {
        state = state.copyWith(requestingCode: false, error: failure.message);
        return false;
      },
    );
  }

  Future<bool> verifyCode(String code) async {
    if (state.email.isEmpty || state.isBusy) return false;
    state = state.copyWith(
      verifyingCode: true,
      clearError: true,
      clearMessage: true,
    );
    final result = await _repository.verifyResetCode(
      email: state.email,
      code: code,
    );
    if (_disposed) return false;
    return result.when(
      success: (valid) {
        if (!valid) {
          state = state.copyWith(
            verifyingCode: false,
            error: 'El código ingresado no es correcto.',
          );
          return false;
        }
        state = state.copyWith(
          code: code,
          verifyingCode: false,
          step: PasswordRecoveryStep.password,
          clearError: true,
        );
        return true;
      },
      failure: (failure) {
        state = state.copyWith(verifyingCode: false, error: failure.message);
        return false;
      },
    );
  }

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state.email.isEmpty || state.code.isEmpty || state.isBusy) return false;
    state = state.copyWith(
      resettingPassword: true,
      clearError: true,
      clearMessage: true,
    );
    final result = await _repository.resetPassword(
      email: state.email,
      code: state.code,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    if (_disposed) return false;
    return result.when(
      success: (_) {
        state = PasswordRecoveryState(
          email: state.email,
          step: PasswordRecoveryStep.success,
        );
        return true;
      },
      failure: (failure) {
        state = state.copyWith(
          resettingPassword: false,
          error: failure.message,
        );
        return false;
      },
    );
  }

  void returnToEmail() {
    state = PasswordRecoveryState(email: state.email);
  }

  void clear() => state = const PasswordRecoveryState();
}

final passwordRecoveryControllerProvider =
    AutoDisposeNotifierProvider<
      PasswordRecoveryController,
      PasswordRecoveryState
    >(PasswordRecoveryController.new);
