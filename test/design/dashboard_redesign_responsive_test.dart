import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:dogplatform/features/authentication/domain/entities/user.dart';
import 'package:dogplatform/features/home/presentation/pages/home_page.dart';
import 'package:dogplatform/features/pets/application/providers.dart';
import 'package:dogplatform/features/pets/presentation/pages/pets_page.dart';
import 'package:dogplatform/features/profile/presentation/pages/profile_page.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_pets_repository.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    testWidgets(
      'dashboard no genera overflow en ${size.width}x${size.height}',
      (tester) async {
        _setView(tester, size);
        final repository = FakeAuthRepository()
          ..currentUserResult = const Result.success(
            User(
              id: '1',
              email: 'jorge@example.com',
              fullName: 'Jorge Gonzales',
            ),
          );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(repository),
              myPetsProvider.overrideWith((ref) async => [samplePetSummary]),
            ],
            child: const MaterialApp(home: HomePage()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(repository),
              myPetsProvider.overrideWith((ref) async => [samplePetSummary]),
            ],
            child: const MaterialApp(home: PetsPage()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(repository),
              myPetsProvider.overrideWith((ref) async => [samplePetSummary]),
            ],
            child: const MaterialApp(home: ProfilePage()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}

void _setView(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
