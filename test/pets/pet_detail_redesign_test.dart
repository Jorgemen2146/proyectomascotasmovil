import 'package:dogplatform/core/router/app_routes.dart';
import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/core/widgets/app_network_image.dart';
import 'package:dogplatform/features/matching/application/providers.dart';
import 'package:dogplatform/features/matching/domain/entities/matching.dart';
import 'package:dogplatform/features/pets/application/providers.dart';
import 'package:dogplatform/features/pets/domain/entities/pet.dart';
import 'package:dogplatform/features/pets/presentation/pages/pet_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_pets_repository.dart';

void main() {
  setUpAll(() => AppConfig.init(environment: Environment.dev));

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
    testWidgets('Pet Detail no genera overflow en $size', (tester) async {
      await _setView(tester, size);
      await _pumpDetail(tester, summary: _longBreedSummary);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('petDetailScrollView')), findsOneWidget);
      expect(find.text('Luna'), findsOneWidget);
      expect(find.text('Bernese Mountain Dog de pelo largo'), findsWidgets);
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Salud'), findsOneWidget);
      expect(find.text('Genealogía'), findsOneWidget);
      expect(find.byKey(const Key('petInfoEspecie')), findsOneWidget);
      expect(find.byKey(const Key('petInfoRaza')), findsOneWidget);
      expect(find.byKey(const Key('petInfoColor')), findsOneWidget);
    });
  }

  testWidgets('muestra foto principal y estado Matching reales', (
    tester,
  ) async {
    const photoUrl = 'https://example.test/luna.jpg';
    final photo = PetPhoto(
      photoId: 'photo-main',
      petId: samplePetDetails.petId,
      url: photoUrl,
      isMain: true,
      createdAt: DateTime.utc(2026),
    );
    await _pumpDetail(
      tester,
      photos: [photo],
      matchingProfile: _activeMatchingProfile,
    );

    final heroImage = tester.widget<AppNetworkImage>(
      find.byType(AppNetworkImage).first,
    );
    expect(heroImage.url, photoUrl);
    expect(heroImage.fit, BoxFit.cover);
    expect(find.text('Perfil activo'), findsOneWidget);
  });

  testWidgets('sin foto ni peso usa estados amigables', (tester) async {
    final withoutWeight = PetDetails(
      petId: samplePetDetails.petId,
      breedId: samplePetDetails.breedId,
      name: samplePetDetails.name,
      birthDate: samplePetDetails.birthDate,
      gender: samplePetDetails.gender,
      color: samplePetDetails.color,
      isSterilized: samplePetDetails.isSterilized,
      description: samplePetDetails.description,
      createdAt: samplePetDetails.createdAt,
    );
    await _pumpDetail(tester, details: withoutWeight);

    final heroImage = tester.widget<AppNetworkImage>(
      find.byType(AppNetworkImage).first,
    );
    expect(heroImage.url, isNull);
    expect(find.text('No registrado'), findsWidgets);
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('Edit, Salud y Genealogía conservan las rutas reales', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.petDetails(samplePetDetails.petId),
      routes: [
        GoRoute(
          path: '/pets/:petId',
          builder: (_, state) =>
              PetDetailPage(petId: state.pathParameters['petId']!),
        ),
        GoRoute(
          path: '/pets/:petId/edit',
          builder: (_, state) => Text('EDIT ${state.pathParameters['petId']}'),
        ),
        GoRoute(
          path: AppRoutes.health,
          builder: (_, state) =>
              Text('HEALTH ${state.uri.queryParameters['petId']}'),
        ),
        GoRoute(
          path: AppRoutes.genealogy,
          builder: (_, state) =>
              Text('GENEALOGY ${state.uri.queryParameters['petId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('petDetailEditar mascota')));
    await tester.pumpAndSettle();
    expect(find.text('EDIT ${samplePetDetails.petId}'), findsOneWidget);

    router.go(AppRoutes.petDetails(samplePetDetails.petId));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salud'));
    await tester.pumpAndSettle();
    expect(find.text('HEALTH ${samplePetDetails.petId}'), findsOneWidget);

    router.go(AppRoutes.petDetails(samplePetDetails.petId));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genealogía'));
    await tester.pumpAndSettle();
    expect(find.text('GENEALOGY ${samplePetDetails.petId}'), findsOneWidget);
  });

  testWidgets('Back vuelve usando la navegación existente', (tester) async {
    final router = GoRouter(
      initialLocation: '/origin',
      routes: [
        GoRoute(
          path: '/origin',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  context.push(AppRoutes.petDetails(samplePetDetails.petId)),
              child: const Text('OPEN_DETAIL'),
            ),
          ),
        ),
        GoRoute(
          path: '/pets/:petId',
          builder: (_, state) =>
              PetDetailPage(petId: state.pathParameters['petId']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('OPEN_DETAIL'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('petDetailVolver')));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_DETAIL'), findsOneWidget);
  });

  testWidgets('soporta escala de texto razonable', (tester) async {
    await _setView(tester, const Size(390, 844));
    await _pumpDetail(tester, textScale: 1.2);

    expect(tester.takeException(), isNull);
    expect(find.text('Información'), findsOneWidget);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  PetDetails? details,
  PetSummary? summary,
  List<PetPhoto> photos = const [],
  MatchingProfile? matchingProfile,
  double textScale = 1,
}) async {
  final selectedDetails = details ?? samplePetDetails;
  final selectedSummary = summary ?? samplePetSummary;
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(
        details: selectedDetails,
        summary: selectedSummary,
        photos: photos,
        matchingProfile: matchingProfile,
      ),
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: PetDetailPage(petId: selectedDetails.petId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<Override> _overrides({
  PetDetails? details,
  PetSummary? summary,
  List<PetPhoto> photos = const [],
  MatchingProfile? matchingProfile,
}) {
  final selectedDetails = details ?? samplePetDetails;
  final selectedSummary = summary ?? samplePetSummary;
  return [
    petDetailsProvider(
      selectedDetails.petId,
    ).overrideWith((ref) async => selectedDetails),
    petPhotosProvider(
      selectedDetails.petId,
    ).overrideWith((ref) async => photos),
    myPetsProvider.overrideWith((ref) async => [selectedSummary]),
    matchingProfileProvider(
      selectedDetails.petId,
    ).overrideWith((ref) async => matchingProfile),
  ];
}

Future<void> _setView(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

final _longBreedSummary = PetSummary(
  id: samplePetSummary.id,
  name: samplePetSummary.name,
  speciesId: samplePetSummary.speciesId,
  speciesName: samplePetSummary.speciesName,
  breedId: samplePetSummary.breedId,
  breedName: 'Bernese Mountain Dog de pelo largo',
  sex: samplePetSummary.sex,
  birthDate: samplePetSummary.birthDate,
  createdAt: samplePetSummary.createdAt,
);

final _activeMatchingProfile = MatchingProfile(
  matchingProfileId: 'matching-profile-1',
  petId: samplePetDetails.petId,
  isActive: true,
  preferredBreedIds: const [],
  minimumAgeMonths: 12,
  maximumAgeMonths: 120,
  requirePedigree: false,
  requireGenealogyValidation: false,
  maximumEstimatedInbreedingCoefficient: 0,
  minimumCompatibilityScore: 0,
  createdAt: DateTime.utc(2026),
  allowMixedBreed: true,
);
