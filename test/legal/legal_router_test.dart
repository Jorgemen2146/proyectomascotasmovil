import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/core/router/app_router.dart';
import 'package:dogplatform/features/authentication/application/auth_state_controller.dart';
import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:dogplatform/features/legal/application/providers.dart';
import 'package:dogplatform/features/legal/domain/entities/legal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';
import 'fakes.dart';

void main() {
  setUpAll(() {
    AppConfig.init(
      environment: Environment.dev,
      apiBaseUrl: 'https://gateway.example.test',
    );
  });

  testWidgets('después de login redirige a reaceptación si hay pendientes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 0.8;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final auth = FakeAuthRepository();
    final legal = FakeLegalRepository()
      ..status = LegalStatus(
        isUpToDate: false,
        pendingDocuments: sampleLegalDocuments,
      );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        legalRepositoryProvider.overrideWithValue(legal),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await container
        .read(authStateControllerProvider.notifier)
        .login(email: 'dog@example.com', password: 'password');
    await tester.pumpAndSettle();

    expect(
      find.text('Hemos actualizado nuestros documentos legales'),
      findsOneWidget,
    );
  });
}
