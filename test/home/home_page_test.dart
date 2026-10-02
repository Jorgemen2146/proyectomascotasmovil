import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:dogplatform/features/home/presentation/pages/home_page.dart';
import 'package:dogplatform/features/pets/application/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_pets_repository.dart';

void main() {
  testWidgets('inicio usa mascotas reales y no muestra salir', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          myPetsProvider.overrideWith((ref) async => [samplePetSummary]),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Luna'), findsWidgets);
    expect(find.text('Golden Retriever'), findsWidgets);
    expect(find.text('En PetLife desde'), findsOneWidget);
    expect(find.text('Max'), findsNothing);
    expect(find.byIcon(Icons.logout_rounded), findsNothing);
  });
}
