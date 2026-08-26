import 'dart:async';

import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/authentication/application/password_recovery_controller.dart';
import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  test(
    'gestiona request, verificación y reset sin conservar secretos',
    () async {
      final repository = FakeAuthRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        passwordRecoveryControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final controller = container.read(
        passwordRecoveryControllerProvider.notifier,
      );

      expect(await controller.requestCode(' dog@example.com '), isTrue);
      expect(repository.lastEmail, 'dog@example.com');
      expect(
        container.read(passwordRecoveryControllerProvider).step,
        PasswordRecoveryStep.code,
      );

      expect(await controller.verifyCode('483921'), isTrue);
      expect(container.read(passwordRecoveryControllerProvider).code, '483921');
      expect(
        container.read(passwordRecoveryControllerProvider).step,
        PasswordRecoveryStep.password,
      );

      expect(
        await controller.resetPassword(
          newPassword: 'Testing456',
          confirmPassword: 'Testing456',
        ),
        isTrue,
      );
      final state = container.read(passwordRecoveryControllerProvider);
      expect(state.step, PasswordRecoveryStep.success);
      expect(state.code, isEmpty);
      expect(repository.lastNewPassword, 'Testing456');

      controller.clear();
      expect(container.read(passwordRecoveryControllerProvider).email, isEmpty);
    },
  );

  test('muestra error de código y permite reintentar', () async {
    final repository = FakeAuthRepository()
      ..verifyResetCodeResult = const Result.failure(
        ValidationFailure('El código ingresado no es correcto.'),
      );
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(
      passwordRecoveryControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      passwordRecoveryControllerProvider.notifier,
    );
    await controller.requestCode('dog@example.com');

    expect(await controller.verifyCode('000000'), isFalse);
    final state = container.read(passwordRecoveryControllerProvider);
    expect(state.verifyingCode, isFalse);
    expect(state.error, 'El código ingresado no es correcto.');
  });

  test('evita doble solicitud mientras la primera está en curso', () async {
    final completer = Completer<Result<String>>();
    final repository = FakeAuthRepository()
      ..forgotPasswordCompleter = completer;
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(
      passwordRecoveryControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      passwordRecoveryControllerProvider.notifier,
    );

    final first = controller.requestCode('dog@example.com');
    expect(await controller.requestCode('dog@example.com'), isFalse);
    expect(repository.forgotPasswordCalls, 1);
    completer.complete(const Result.success('Mensaje genérico'));
    expect(await first, isTrue);
  });
}

ProviderContainer _container(FakeAuthRepository repository) =>
    ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
