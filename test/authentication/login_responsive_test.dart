import 'package:dogplatform/features/authentication/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [Size(360, 640), Size(390, 780), Size(430, 900)]) {
    testWidgets('Login se adapta sin scroll en ${size.height}px', (
      tester,
    ) async {
      await _setView(tester, size);
      await _pumpLogin(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsNothing);
      final createAccount = find.text('Crear cuenta');
      expect(createAccount, findsOneWidget);
      expect(
        tester.getBottomRight(createAccount).dy,
        lessThanOrEqualTo(size.height),
      );
    });
  }

  testWidgets('Login compacto soporta textScale razonable', (tester) async {
    const size = Size(390, 700);
    await _setView(tester, size);
    await _pumpLogin(tester, textScale: 1.15);

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });

  testWidgets('Login permite scroll cuando se abre el teclado', (tester) async {
    await _setView(tester, const Size(390, 780));
    await _pumpLogin(tester);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() => tester.view.resetViewInsets());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}

Future<void> _pumpLogin(WidgetTester tester, {double textScale = 1}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const LoginPage(),
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
