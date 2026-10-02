import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/authentication/application/auth_state.dart';
import 'package:dogplatform/features/authentication/application/auth_state_controller.dart';
import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dogplatform/features/legal/domain/entities/legal.dart';
import 'package:dogplatform/features/authentication/domain/entities/external_auth.dart';
import 'package:dogplatform/features/authentication/domain/entities/user.dart';
import 'package:dogplatform/features/authentication/domain/services/external_identity_service.dart';

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
          legalConsents: const [
            LegalConsentSelection(type: 'TermsAndConditions', version: '1.0'),
          ],
          phoneNumber: null,
        );

    expect(success, isTrue);
    expect(
      container.read(authStateControllerProvider).status,
      AuthStatus.unauthenticated,
    );
  });

  test('Login externo exitoso autentica con la sesión DogPlatform', () async {
    final repository = FakeAuthRepository()
      ..externalLoginResult = const Result.success(
        ExternalAuthAuthenticated(
          User(id: 'social', email: 'social@test.com', fullName: 'Social User'),
        ),
      );
    final identity = _FakeExternalIdentityService(
      const ExternalProviderSuccess(
        ExternalProviderCredential(
          provider: ExternalAuthProvider.google,
          credential: 'id-token',
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        externalIdentityServiceProvider.overrideWithValue(identity),
      ],
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(authStateControllerProvider.notifier)
        .externalLogin(provider: ExternalAuthProvider.google);

    expect(outcome, isA<ExternalAuthAuthenticated>());
    expect(
      container.read(authStateControllerProvider).status,
      AuthStatus.authenticated,
    );
    expect(identity.requestedProvider, ExternalAuthProvider.google);
  });

  test('Cancelar proveedor no muestra error ni autentica', () async {
    final repository = FakeAuthRepository();
    final identity = _FakeExternalIdentityService(
      const ExternalProviderCancelled(),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        externalIdentityServiceProvider.overrideWithValue(identity),
      ],
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(authStateControllerProvider.notifier)
        .externalLogin(provider: ExternalAuthProvider.apple);

    expect(outcome, isNull);
    expect(container.read(authStateControllerProvider).errorMessage, isNull);
    expect(
      container.read(authStateControllerProvider).status,
      isNot(AuthStatus.authenticated),
    );
  });

  test('Logout limpia también el estado local de proveedores', () async {
    final repository = FakeAuthRepository();
    final identity = _FakeExternalIdentityService(
      const ExternalProviderCancelled(),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        externalIdentityServiceProvider.overrideWithValue(identity),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authStateControllerProvider.notifier).logout();

    expect(repository.logoutCalls, 1);
    expect(identity.signOutCalls, 1);
  });
}

class _FakeExternalIdentityService implements ExternalIdentityService {
  _FakeExternalIdentityService(this.result);

  final ExternalProviderResult result;
  ExternalAuthProvider? requestedProvider;
  int signOutCalls = 0;

  @override
  Future<ExternalProviderResult> signIn(ExternalAuthProvider provider) async {
    requestedProvider = provider;
    return result;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}
