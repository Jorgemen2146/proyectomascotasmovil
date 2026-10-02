import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/router/app_routes.dart';
import 'package:dogplatform/core/widgets/app_button.dart';
import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:dogplatform/features/authentication/presentation/pages/register_page.dart';
import 'package:dogplatform/features/legal/application/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth_repository.dart';
import 'fakes.dart';

void main() {
  testWidgets('checkbox comienza false y registro queda bloqueado', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await _pumpRegister(tester, auth: auth);

    expect(find.textContaining('PetLife'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
    expect(auth.registerCalls, 0);
  });

  testWidgets('Términos abre su ruta independiente', (tester) async {
    await _pumpRegister(tester, auth: FakeAuthRepository());

    final link = find.byKey(const Key('registerTermsLink'));
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.text('terms-page'), findsOneWidget);
  });

  testWidgets('Privacidad abre su ruta independiente', (tester) async {
    await _pumpRegister(tester, auth: FakeAuthRepository());

    final link = find.byKey(const Key('registerPrivacyLink'));
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.text('privacy-page'), findsOneWidget);
  });

  testWidgets('fallo al cargar documentos muestra retry y bloquea registro', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await _pumpRegister(tester, auth: auth, failDocuments: true);

    expect(
      find.text('No pudimos cargar los términos y la política de privacidad.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    expect(tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
    expect(auth.registerCalls, 0);
  });
}

Future<void> _pumpRegister(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  bool failDocuments = false,
}) async {
  final router = GoRouter(
    initialLocation: AppRoutes.register,
    routes: [
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.legalTerms,
        builder: (_, _) =>
            const Text('terms-page', textDirection: TextDirection.ltr),
      ),
      GoRoute(
        path: AppRoutes.legalPrivacy,
        builder: (_, _) =>
            const Text('privacy-page', textDirection: TextDirection.ltr),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        legalDocumentsProvider.overrideWith((ref) async {
          if (failDocuments) {
            throw const NetworkFailure('Sin conexión');
          }
          return sampleLegalDocuments;
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}
