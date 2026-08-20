import 'package:dogplatform/core/router/app_routes.dart';
import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:dogplatform/features/authentication/presentation/pages/login_page.dart';
import 'package:dogplatform/features/authentication/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('Register exitoso navega a Verify Email con solo el email', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final router = GoRouter(
      initialLocation: AppRoutes.register,
      routes: [
        GoRoute(
          path: AppRoutes.register,
          builder: (_, _) => const RegisterPage(),
        ),
        GoRoute(
          path: AppRoutes.verifyEmail,
          builder: (_, state) =>
              Text('verify:${state.extra}', textDirection: TextDirection.ltr),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Dog');
    await tester.enterText(fields.at(1), 'User');
    await tester.enterText(fields.at(2), 'dog@example.com');
    await tester.enterText(fields.at(3), 'password');
    await tester.enterText(fields.at(4), 'password');
    await tester.tap(find.byType(Checkbox));
    final submit = find.text('Crear cuenta').last;
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('verify:dog@example.com'), findsOneWidget);
    expect(repository.registerCalls, 1);
    expect(repository.lastFirstName, 'Dog');
    expect(repository.lastLastName, 'User');
    expect(repository.lastPhoneNumber, isNull);
    expect(router.routeInformationProvider.value.uri.query, isEmpty);
  });

  testWidgets('Login EMAIL_NOT_VERIFIED navega a Verify Email', (tester) async {
    final repository = FakeAuthRepository()
      ..loginResult = const Result.failure(
        ServerFailure(
          'Debes verificar tu correo antes de iniciar sesión.',
          statusCode: 403,
          errorCode: 'EMAIL_NOT_VERIFIED',
        ),
      );
    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
        GoRoute(
          path: AppRoutes.verifyEmail,
          builder: (_, state) =>
              Text('verify:${state.extra}', textDirection: TextDirection.ltr),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'dog@example.com');
    await tester.enterText(fields.at(1), 'password');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('verify:dog@example.com'), findsOneWidget);
  });
}
