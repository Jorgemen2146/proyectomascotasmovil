import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/features/matching/application/providers.dart';
import 'package:dogplatform/features/matching/presentation/pages/matching_candidate_page.dart';
import 'package:dogplatform/features/matching/presentation/pages/matching_match_detail_page.dart';
import 'package:dogplatform/features/matching/presentation/pages/matching_page.dart';
import 'package:dogplatform/features/matching/presentation/pages/matching_requests_page.dart';
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

  testWidgets('search muestra candidato y advertencia genealógica', (
    tester,
  ) async {
    final repository = FakeMatchingRepository()
      ..profile = sampleProfile
      ..candidates = [sampleCandidate];
    await _largeView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(repository),
          myPetsProvider.overrideWith((ref) async => [samplePet]),
          breedsProvider(1).overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: MatchingPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('Golden Retriever'), findsOneWidget);
    expect(find.text('Existe parentesco registrado'), findsOneWidget);
    expect(find.byKey(const Key('matchingFilters')), findsOneWidget);
  });

  testWidgets('perfil inactivo se activa con consentimiento explícito', (
    tester,
  ) async {
    final repository = FakeMatchingRepository();
    await _largeView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(repository),
          myPetsProvider.overrideWith((ref) async => [samplePet]),
          breedsProvider(1).overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: MatchingPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Andrea aún no está visible'), findsOneWidget);
    await tester.tap(find.byKey(const Key('activateMatchingProfile')));
    await tester.pump();
    await tester.tap(find.text('Guardar y activar'));
    await tester.pumpAndSettle();
    expect(repository.calls, contains('createProfile'));
  });

  testWidgets(
    'perfil público oculta contacto antes del match y envía request',
    (tester) async {
      final repository = FakeMatchingRepository()..candidate = sampleCandidate;
      await _largeView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(repository),
            petDetailsProvider(
              'mine',
            ).overrideWith((ref) async => samplePetDetails),
          ],
          child: const MaterialApp(
            home: MatchingCandidatePage(
              sourcePetId: 'mine',
              candidatePetId: 'candidate',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Disponible después de que ambos acepten la solicitud.'),
        findsOneWidget,
      );
      expect(find.textContaining('+51'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('sendMatchingRequest')));
      await tester.tap(find.byKey(const Key('sendMatchingRequest')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('matchingRequestMessage')),
        'Hola Luna',
      );
      await tester.tap(find.text('Enviar solicitud').last);
      await tester.pumpAndSettle();
      expect(repository.calls, contains('send'));
      expect(repository.lastMessage, 'Hola Luna');
      expect(find.text('Pendiente de respuesta'), findsOneWidget);
    },
  );

  testWidgets('recibidas acepta teléfono y enviadas permite cancelar', (
    tester,
  ) async {
    final repository = FakeMatchingRepository()
      ..incoming = [sampleRequest]
      ..outgoing = [sampleRequest];
    await _largeView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [matchingRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: MatchingRequestsPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shareMatchingPhone')));
    await tester.tap(find.text('Aceptar solicitud'));
    await tester.pumpAndSettle();
    expect(repository.calls, contains('accept'));
    expect(repository.lastSharePhone, isTrue);

    await tester.tap(find.text('Enviadas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar solicitud'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar solicitud').last);
    await tester.pumpAndSettle();
    expect(repository.calls, contains('cancel'));
  });

  testWidgets('sin intención propone y refresca estado persistido', (
    tester,
  ) async {
    final repository = FakeMatchingRepository();
    await _largeView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [matchingRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: MatchingMatchDetailPage(matchId: 'match-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('+51 999 000 000'), findsOneWidget);
    expect(
      find.text('El propietario no ha compartido su teléfono.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const Key('proposeBreedingIntent')));
    await tester.tap(find.byKey(const Key('proposeBreedingIntent')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar propuesta'));
    await tester.pumpAndSettle();
    expect(repository.calls, contains('propose'));
    expect(find.text('Propuesta enviada'), findsOneWidget);
    expect(find.text('Aceptar propuesta'), findsNothing);
    expect(find.text('Cancelar propuesta'), findsOneWidget);
    await tester.tap(find.text('Cancelar propuesta'));
    await tester.pumpAndSettle();
    expect(repository.calls, contains('cancelIntent'));
    expect(find.text('Intención cancelada'), findsOneWidget);
  });

  testWidgets('receptor de Proposed solo puede aceptar', (tester) async {
    final repository = FakeMatchingRepository()
      ..breedingIntent = sampleReceivedIntent;
    await _pumpMatch(tester, repository);

    expect(find.text('Propuesta de posible camada'), findsOneWidget);
    expect(find.text('Aceptar propuesta'), findsOneWidget);
    expect(find.textContaining('Cancelar'), findsNothing);
    expect(
      find.text('Fecha aproximada considerada: 15 nov 2026'),
      findsOneWidget,
    );
    await tester.tap(find.text('Aceptar propuesta'));
    await tester.pumpAndSettle();
    expect(repository.calls, contains('acceptIntent'));
    expect(find.text('Intención de camada acordada'), findsOneWidget);
  });

  testWidgets('Agreed muestra aceptación y permite cancelar', (tester) async {
    final repository = FakeMatchingRepository()
      ..breedingIntent = sampleAgreedIntent;
    await _pumpMatch(tester, repository);

    expect(find.text('Intención de camada acordada'), findsOneWidget);
    expect(find.text('Aceptada el 26 ago 2026'), findsOneWidget);
    expect(find.text('Aceptar propuesta'), findsNothing);
    expect(find.text('Cancelar intención'), findsOneWidget);
  });

  testWidgets('Cancelled permite proponer una intención nueva', (tester) async {
    final repository = FakeMatchingRepository()
      ..breedingIntent = sampleCancelledIntent;
    await _pumpMatch(tester, repository);

    expect(find.text('Intención cancelada'), findsOneWidget);
    expect(find.text('Proponer nueva intención'), findsOneWidget);
  });

  testWidgets('Completed es informativo y no muestra acciones', (tester) async {
    final repository = FakeMatchingRepository()
      ..breedingIntent = sampleCompletedIntent;
    await _pumpMatch(tester, repository);

    expect(find.text('Intención completada'), findsOneWidget);
    expect(find.byKey(const Key('acceptBreedingIntent')), findsNothing);
    expect(find.byKey(const Key('cancelBreedingIntent')), findsNothing);
    expect(find.byKey(const Key('proposeBreedingIntent')), findsNothing);
  });

  testWidgets('pull-to-refresh conserva la intención desde backend', (
    tester,
  ) async {
    final repository = FakeMatchingRepository()
      ..breedingIntent = sampleReceivedIntent;
    await _pumpMatch(tester, repository);
    final callsBefore = repository.calls
        .where((call) => call == 'getMatch')
        .length;

    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Propuesta de posible camada'), findsOneWidget);
    expect(
      repository.calls.where((call) => call == 'getMatch').length,
      greaterThan(callsBefore),
    );
  });
}

Future<void> _pumpMatch(
  WidgetTester tester,
  FakeMatchingRepository repository,
) async {
  await _largeView(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [matchingRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(
        home: MatchingMatchDetailPage(matchId: 'match-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _largeView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

final samplePet = PetSummary(
  id: 'mine',
  name: 'Andrea',
  speciesId: 1,
  speciesName: 'Gato',
  breedId: 1,
  breedName: 'Mestizo',
  sex: 'M',
  createdAt: DateTime.utc(2025),
);

final samplePetDetails = PetDetails(
  petId: 'mine',
  breedId: 1,
  name: 'Andrea',
  gender: 'M',
  isSterilized: false,
  createdAt: DateTime.utc(2025),
);
