import 'package:dogplatform/features/legal/application/providers.dart';
import 'package:dogplatform/features/legal/presentation/pages/legal_document_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  testWidgets('muestra título, versión, fecha y contenido del backend', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          legalDocumentsProvider.overrideWith(
            (ref) async => sampleLegalDocuments,
          ),
        ],
        child: const MaterialApp(
          home: LegalDocumentPage(documentType: 'TermsAndConditions'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Términos y Condiciones'), findsWidgets);
    expect(find.text('Versión 2.4'), findsOneWidget);
    expect(find.text('Última actualización: 20/08/2026'), findsOneWidget);
    expect(find.text('Contenido completo de términos.'), findsOneWidget);
  });
}
