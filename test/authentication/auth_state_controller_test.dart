import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/authentication/application/auth_state.dart';
import 'package:dogplatform/features/authentication/application/auth_state_controller.dart';
import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  test('Login 403 EMAIL_NOT_VERIFIED produce outcome específico', () async {
    final repository = FakeAuthRepository()
      ..loginResult = const Result.failure(
        ServerFailure(
          'Debes verificar tu correo antes de iniciar sesión.',
          statusCode: 403,
          errorCode: 'EMAIL_NOT_VERIFIED',
        ),
      );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(authStateControllerProvider.notifier)
        .login(email: 'dog@example.com', password: 'password');

    expect(outcome, LoginOutcome.emailNotVerified);
    expect(
      container.read(authStateControllerProvider).status,
      isNot(AuthStatus.authenticated),
    );
  });

  test('Login normal sigue autenticando al usuario', () async {
    final repository = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(authStateControllerProvider.notifier)
        .login(email: 'dog@example.com', password: 'password');

    expect(outcome, LoginOutcome.success);
    expect(
      container.read(authStateControllerProvider).status,
      AuthStatus.authenticated,
    );
  });

  test('Register exitoso permanece unauthenticated', () async {
    final repository = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authStateControllerProvider.notifier)
        .register(
          firstName: 'Dog',
          lastName: 'User',
          email: 'dog@example.com',
          password: 'password',
          phoneNumber: null,
        );

    expect(success, isTrue);
    expect(
      container.read(authStateControllerProvider).status,
      AuthStatus.unauthenticated,
    );
  });
}
