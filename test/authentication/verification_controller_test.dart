import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:dogplatform/features/authentication/application/verification_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        verificationCooldownSecondsProvider.overrideWithValue(0),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('Verify Email válido envía email y código', () async {
    final result = await container
        .read(verificationControllerProvider('dog@example.com').notifier)
        .verify('123456');

    expect(result, isTrue);
    expect(repository.verifyCalls, 1);
    expect(repository.lastEmail, 'dog@example.com');
    expect(repository.lastCode, '123456');
  });

  test('código inválido del backend conserva su mensaje', () async {
    repository.verifyResult = const Result.failure(
      ValidationFailure('El código ingresado no es válido.'),
    );

    final provider = verificationControllerProvider('dog@example.com');
    final result = await container.read(provider.notifier).verify('123456');

    expect(result, isFalse);
    expect(
      container.read(provider).errorMessage,
      'El código ingresado no es válido.',
    );
  });

  test('código que no tiene 6 dígitos no llama al repository', () async {
    final provider = verificationControllerProvider('dog@example.com');
    final result = await container.read(provider.notifier).verify('12345');

    expect(result, isFalse);
    expect(repository.verifyCalls, 0);
    expect(container.read(provider).errorMessage, contains('6 dígitos'));
  });

  test('Resend exitoso llama al repository', () async {
    final result = await container
        .read(verificationControllerProvider('dog@example.com').notifier)
        .resend();

    expect(result, isTrue);
    expect(repository.resendCalls, 1);
  });

  test('cooldown bloquea reenvíos hasta llegar a cero', () async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        verificationCooldownSecondsProvider.overrideWithValue(2),
        verificationCooldownTickProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
      ],
    );
    final provider = verificationControllerProvider('dog@example.com');
    final subscription = container.listen(provider, (_, _) {});

    expect(await container.read(provider.notifier).resend(), isFalse);
    expect(repository.resendCalls, 0);
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(container.read(provider).canResend, isTrue);
    expect(await container.read(provider.notifier).resend(), isTrue);
    expect(container.read(provider).cooldownSeconds, 2);
    expect(repository.resendCalls, 1);
    subscription.close();
  });
}
