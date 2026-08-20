import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'providers.dart';

class VerificationState {
  const VerificationState({
    required this.email,
    this.isVerifying = false,
    this.isResending = false,
    this.cooldownSeconds = 60,
    this.errorMessage,
  });

  final String email;
  final bool isVerifying;
  final bool isResending;
  final int cooldownSeconds;
  final String? errorMessage;

  bool get canResend => cooldownSeconds == 0 && !isResending && !isVerifying;

  VerificationState copyWith({
    bool? isVerifying,
    bool? isResending,
    int? cooldownSeconds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VerificationState(
      email: email,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final verificationCooldownSecondsProvider = Provider<int>((ref) => 60);
final verificationCooldownTickProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

class VerificationController
    extends AutoDisposeFamilyNotifier<VerificationState, String> {
  Timer? _timer;

  @override
  VerificationState build(String email) {
    ref.onDispose(() => _timer?.cancel());
    final seconds = ref.read(verificationCooldownSecondsProvider);
    _scheduleCountdown();
    return VerificationState(email: email, cooldownSeconds: seconds);
  }

  Future<bool> verify(String code) async {
    if (state.isVerifying || state.isResending) return false;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      state = state.copyWith(errorMessage: 'Ingresa un código de 6 dígitos.');
      return false;
    }

    state = state.copyWith(isVerifying: true, clearError: true);
    final result = await ref
        .read(verifyEmailUseCaseProvider)
        .call(email: state.email, code: code);
    return result.when(
      success: (_) {
        state = state.copyWith(isVerifying: false, clearError: true);
        return true;
      },
      failure: (failure) {
        state = state.copyWith(
          isVerifying: false,
          errorMessage: _friendlyMessage(failure),
        );
        return false;
      },
    );
  }

  Future<bool> resend() async {
    if (!state.canResend) return false;
    state = state.copyWith(isResending: true, clearError: true);
    final result = await ref
        .read(resendVerificationUseCaseProvider)
        .call(email: state.email);
    return result.when(
      success: (_) {
        state = state.copyWith(isResending: false);
        _startCooldown(ref.read(verificationCooldownSecondsProvider));
        return true;
      },
      failure: (failure) {
        state = state.copyWith(
          isResending: false,
          errorMessage: _friendlyMessage(failure),
        );
        return false;
      },
    );
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    state = state.copyWith(cooldownSeconds: seconds);
    if (seconds == 0) return;
    _scheduleCountdown();
  }

  void _scheduleCountdown() {
    if (ref.read(verificationCooldownSecondsProvider) == 0) return;
    _timer = Timer.periodic(ref.read(verificationCooldownTickProvider), (
      timer,
    ) {
      if (state.cooldownSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(cooldownSeconds: 0);
      } else {
        state = state.copyWith(cooldownSeconds: state.cooldownSeconds - 1);
      }
    });
  }

  String _friendlyMessage(AppFailure failure) {
    if (failure is NetworkFailure) {
      return 'No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.';
    }
    return failure.message;
  }
}

final verificationControllerProvider =
    AutoDisposeNotifierProviderFamily<
      VerificationController,
      VerificationState,
      String
    >(VerificationController.new);
