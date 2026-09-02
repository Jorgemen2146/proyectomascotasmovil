import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/features/matching/application/providers.dart';
import 'package:dogplatform/features/matching/presentation/pages/matching_page.dart';
import 'package:dogplatform/features/pets/application/providers.dart';
import 'package:dogplatform/features/pets/domain/entities/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  setUpAll(() {
    AppConfig.init(
      environment: Environment.dev,
      apiBaseUrl: 'https://gateway.example.test',
    );
  });

  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('Pareja y navegación no desbordan a ${width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = FakeMatchingRepository()
        ..profile = sampleProfile
        ..candidates = [sampleCandidate];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(repository),
            myPetsProvider.overrideWith((ref) async => [_pet]),
          ],
          child: const MaterialApp(home: MatchingPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pareja'), findsOneWidget);
      expect(find.text('Mascotas'), findsOneWidget);
      expect(find.text('Parejas recomendadas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

final _pet = PetSummary(
  id: 'mine',
  name: 'Andrea',
  speciesId: 1,
  speciesName: 'Perro',
  breedId: 1,
  breedName: 'Golden Retriever',
  sex: 'M',
  birthDate: DateTime.utc(2023, 1, 1),
  createdAt: DateTime.utc(2023, 1, 1),
);
