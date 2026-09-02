import 'package:dogplatform/core/router/app_routes.dart';
import 'package:dogplatform/features/authentication/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final size in const [
    Size(320, 568),
    Size(360, 640),
    Size(360, 800),
    Size(375, 667),
    Size(390, 844),
    Size(412, 915),
    Size(430, 932),
    Size(768, 1024),
  ]) {
    testWidgets('Login separa texto, animales y formulario en $size', (
      tester,
    ) async {
      await _setView(tester, size);
      await _pumpLogin(tester);

      expect(tester.takeException(), isNull);
      if (size.height >= 667) {
        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        expect(scrollable.position.maxScrollExtent, 0);
      }
      final createAccount = find.text('Crea tu cuenta');
      expect(createAccount, findsOneWidget);

      final subtitle = find.text('Inicia sesión para continuar');
      final animals = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/01_dog_cat_login.png',
      );
      final emailField = find.byType(TextFormField).first;
      expect(
        tester.getBottomLeft(subtitle).dy,
        lessThan(tester.getTopLeft(animals).dy),
      );
      expect(
        tester.getBottomLeft(animals).dy,
        lessThanOrEqualTo(tester.getTopLeft(emailField).dy),
      );
    });
  }

  testWidgets('Login compacto soporta textScale razonable', (tester) async {
    const size = Size(390, 700);
    await _setView(tester, size);
    await _pumpLogin(tester, textScale: 1.15);

    expect(tester.takeException(), isNull);
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.maxScrollExtent, 0);
    expect(find.text('Crea tu cuenta'), findsOneWidget);
  });

  testWidgets('Login permite scroll cuando se abre el teclado', (tester) async {
    await _setView(tester, const Size(390, 780));
    await _pumpLogin(tester);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() => tester.view.resetViewInsets());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('respeta la jerarquía visual aprobada', (tester) async {
    await _setView(tester, const Size(390, 844));
    await _pumpLogin(tester);

    final loginY = tester.getTopLeft(find.text('Iniciar sesión')).dy;
    final accountY = tester.getTopLeft(find.text('Crea tu cuenta')).dy;
    final dividerY = tester.getTopLeft(find.text('o continúa con')).dy;
    final securityY = tester
        .getTopLeft(find.text('Tu información está segura'))
        .dy;

    expect(loginY, lessThan(accountY));
    expect(accountY, lessThan(dividerY));
    expect(dividerY, lessThan(securityY));
  });

  testWidgets('mantiene validaciones y mostrar/ocultar contraseña', (
    tester,
  ) async {
    await _setView(tester, const Size(390, 844));
    await _pumpLogin(tester);

    final fields = find.byType(TextFormField);
    final passwordInput = find.descendant(
      of: fields.at(1),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(passwordInput).obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(tester.widget<EditableText>(passwordInput).obscureText, isFalse);

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
  });

  testWidgets('card de cuenta y enlace de recuperación usan rutas reales', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
        GoRoute(
          path: AppRoutes.register,
          builder: (_, _) => const Text('REGISTER_DESTINATION'),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, _) => const Text('FORGOT_DESTINATION'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createAccountCard')));
    await tester.pumpAndSettle();
    expect(find.text('REGISTER_DESTINATION'), findsOneWidget);

    router.go(AppRoutes.login);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forgotPasswordLink')));
    await tester.pumpAndSettle();
    expect(find.text('FORGOT_DESTINATION'), findsOneWidget);
  });
}

Future<void> _pumpLogin(WidgetTester tester, {double textScale = 1}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const LoginPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _setView(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
