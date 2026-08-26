import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/authentication/application/password_recovery_controller.dart';
import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:dogplatform/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:dogplatform/features/authentication/presentation/pages/login_page.dart';
import 'package:dogplatform/features/authentication/presentation/pages/password_reset_success_page.dart';
import 'package:dogplatform/features/authentication/presentation/pages/reset_password_page.dart';
import 'package:dogplatform/features/authentication/presentation/pages/verify_reset_code_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('Login abre Recuperar contraseña', (tester) async {
    await _largeView(tester);
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('forgotPasswordLink')));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar contraseña'), findsOneWidget);
  });

  testWidgets('valida correo requerido e inválido', (tester) async {
    await _largeView(tester);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ForgotPasswordPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('requestResetCode')));
    await tester.pump();
    expect(find.text('Ingresa un correo válido'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'correo-invalido');
    await tester.tap(find.byKey(const Key('requestResetCode')));
    await tester.pump();
    expect(find.text('Ingresa un correo válido'), findsOneWidget);
  });

  testWidgets('solicita código y navega a Verify', (tester) async {
    await _largeView(tester);
    final repository = FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final router = _router(initialLocation: '/forgot-password');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'dog@example.com');
    await tester.tap(find.byKey(const Key('requestResetCode')));
    await tester.pumpAndSettle();

    expect(repository.forgotPasswordCalls, 1);
    expect(find.text('Verifica tu correo'), findsOneWidget);
    expect(find.textContaining('dog***@example.com'), findsOneWidget);
  });

  testWidgets('verifica código válido y mapea código inválido', (tester) async {
    await _largeView(tester);
    final repository = FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      passwordRecoveryControllerProvider,
      (_, _) {},
    );
    addTearDown(keepAlive.close);
    await container
        .read(passwordRecoveryControllerProvider.notifier)
        .requestCode('dog@example.com');
    final router = _router(initialLocation: '/verify-reset-code');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    repository.verifyResetCodeResult = const Result.failure(
      ValidationFailure('El código ingresado no es correcto.'),
    );
    await tester.enterText(find.byKey(const Key('resetCodeField')), '000000');
    await tester.tap(find.byKey(const Key('verifyResetCode')));
    await tester.pumpAndSettle();
    expect(find.text('El código ingresado no es correcto.'), findsOneWidget);

    repository.verifyResetCodeResult = const Result.success(true);
    await tester.enterText(find.byKey(const Key('resetCodeField')), '483921');
    await tester.tap(find.byKey(const Key('verifyResetCode')));
    await tester.pumpAndSettle();
    expect(repository.lastCode, '483921');
  });

  testWidgets('reenvío limpia código y conserva correo', (tester) async {
    await _largeView(tester);
    final repository = FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      passwordRecoveryControllerProvider,
      (_, _) {},
    );
    addTearDown(keepAlive.close);
    await container
        .read(passwordRecoveryControllerProvider.notifier)
        .requestCode('dog@example.com');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: VerifyResetCodePage(cooldownSeconds: 0)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('resetCodeField')), '123456');

    await tester.tap(find.byKey(const Key('resendResetCode')));
    await tester.pumpAndSettle();

    expect(repository.forgotPasswordCalls, 2);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('resetCodeField')))
          .controller
          ?.text,
      isEmpty,
    );
    expect(
      container.read(passwordRecoveryControllerProvider).email,
      'dog@example.com',
    );
  });

  testWidgets('valida policy, confirmación y reset exitoso', (tester) async {
    await _largeView(tester);
    final repository = FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      passwordRecoveryControllerProvider,
      (_, _) {},
    );
    addTearDown(keepAlive.close);
    final controller = container.read(
      passwordRecoveryControllerProvider.notifier,
    );
    await controller.requestCode('dog@example.com');
    await controller.verifyCode('483921');
    final router = _router(initialLocation: '/reset-password');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'short');
    await tester.enterText(fields.at(1), 'different');
    await tester.tap(find.byKey(const Key('resetPassword')));
    await tester.pump();
    expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);

    await tester.enterText(fields.at(0), 'Testing456');
    await tester.enterText(fields.at(1), 'Testing456');
    await tester.tap(find.byKey(const Key('resetPassword')));
    await tester.pumpAndSettle();
    expect(repository.resetPasswordCalls, 1);
    expect(container.read(passwordRecoveryControllerProvider).code, isEmpty);
  });

  testWidgets('éxito limpia estado y vuelve a Login sin back sensible', (
    tester,
  ) async {
    await _largeView(tester);
    final repository = FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      passwordRecoveryControllerProvider,
      (_, _) {},
    );
    addTearDown(keepAlive.close);
    final controller = container.read(
      passwordRecoveryControllerProvider.notifier,
    );
    await controller.requestCode('dog@example.com');
    await controller.verifyCode('483921');
    await controller.resetPassword(
      newPassword: 'Testing456',
      confirmPassword: 'Testing456',
    );
    final router = _router(initialLocation: '/password-reset-success');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('passwordResetLogin')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(container.read(passwordRecoveryControllerProvider).email, isEmpty);
    expect(router.canPop(), isFalse);
  });

  testWidgets('pantalla recovery compacta no genera overflow', (tester) async {
    await _setView(tester, const Size(360, 640));
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ForgotPasswordPage())),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

ProviderContainer _container(FakeAuthRepository repository) =>
    ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );

GoRouter _router({required String initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, _) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/verify-reset-code',
      builder: (_, _) => const VerifyResetCodePage(cooldownSeconds: 0),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (_, _) => const ResetPasswordPage(),
    ),
    GoRoute(
      path: '/password-reset-success',
      builder: (_, _) => const PasswordResetSuccessPage(),
    ),
  ],
);

Future<void> _largeView(WidgetTester tester) =>
    _setView(tester, const Size(900, 1400));

Future<void> _setView(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
