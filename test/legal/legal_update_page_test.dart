import 'package:dogplatform/features/legal/application/providers.dart';
import 'package:dogplatform/features/legal/domain/entities/legal.dart';
import 'package:dogplatform/features/legal/presentation/pages/legal_update_page.dart';
import 'package:dogplatform/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  testWidgets('requiere aceptación explícita de todos los pendientes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeLegalRepository()
      ..status = LegalStatus(
        isUpToDate: false,
        pendingDocuments: sampleLegalDocuments,
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [legalRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LegalUpdatePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Versión 2.4'), findsOneWidget);
    expect(find.text('Versión 3.1'), findsOneWidget);
    final action = find.byType(AppButton);
    await tester.ensureVisible(action);
    expect(tester.widget<AppButton>(action).onPressed, isNull);

    final firstConsent = find.byType(CheckboxListTile).at(0);
    await tester.ensureVisible(firstConsent);
    await tester.tap(firstConsent);
    await tester.pump();
    final secondConsent = find.byType(CheckboxListTile).at(1);
    await tester.ensureVisible(secondConsent);
    await tester.tap(secondConsent);
    await tester.pump();
    await tester.ensureVisible(action);
    await tester.tap(find.text('Aceptar y continuar'));
    await tester.pumpAndSettle();

    expect(repository.acceptedIds, ['terms-id', 'privacy-id']);
  });
}
