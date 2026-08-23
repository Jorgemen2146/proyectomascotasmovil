import 'package:dogplatform/core/theme/app_theme.dart';
import 'package:dogplatform/features/health/application/providers.dart';
import 'package:dogplatform/features/health/domain/entities/health.dart';
import 'package:dogplatform/features/health/presentation/pages/health_page.dart';
import 'package:dogplatform/features/pets/application/providers.dart';
import 'package:dogplatform/features/pets/domain/entities/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('prioriza atención, expande y preselecciona Registrar dosis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPetsProvider.overrideWith((ref) async => [_pet]),
          vaccinationStatusProvider(
            'pet-1',
          ).overrideWith((ref) async => _status),
          petVaccinationsProvider(
            'pet-1',
          ).overrideWith((ref) async => [_status.vaccines.last]),
          vaccinesBySpeciesProvider(2).overrideWith(
            (ref) async => const [
              Vaccine(vaccineId: 1, speciesId: 2, name: 'Rabia', isCore: true),
            ],
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HealthPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lo que necesita atención'), findsOneWidget);
    expect(find.text('Sin registro'), findsOneWidget);
    expect(find.text('Calicivirus'), findsNothing);
    expect(find.text('Registrar una vacunación'), findsOneWidget);

    await tester.tap(find.text('Ver todo'));
    await tester.pumpAndSettle();
    expect(find.text('Calicivirus'), findsOneWidget);

    await tester.tap(find.text('Registrar dosis').first);
    await tester.pumpAndSettle();

    expect(find.text('Registrar vacuna'), findsOneWidget);
    expect(find.text('Andrea Kitty'), findsWidgets);
    expect(find.text('Rabia'), findsWidgets);
    expect(find.byKey(const Key('vaccineField')), findsNothing);
    expect(find.text('Guardar vacuna'), findsOneWidget);
  });

  testWidgets(
    'eligible=false aparece solo en Próximamente y elige la fecha menor',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myPetsProvider.overrideWith((ref) async => [_pet]),
            vaccinationStatusProvider(
              'pet-1',
            ).overrideWith((ref) async => _youngPetStatus),
            petVaccinationsProvider(
              'pet-1',
            ).overrideWith((ref) async => const []),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const HealthPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Andrea Kitty todavía está creciendo'), findsOneWidget);
      expect(find.text('Próximamente'), findsNWidgets(4));
      expect(find.text('Lo que necesita atención'), findsNothing);
      expect(find.text('Registrar dosis'), findsNothing);
      expect(find.text('Parvovirus'), findsNWidgets(2));
      expect(find.text('Faltan 18 días'), findsNWidgets(2));
      await tester.scrollUntilVisible(
        find.text('Resumen de salud'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Registrar una vacunación'), findsOneWidget);
    },
  );
}

final _pet = PetSummary(
  id: 'pet-1',
  name: 'Andrea Kitty',
  speciesId: 2,
  speciesName: 'Gato',
  breedId: 4,
  breedName: 'Común',
  sex: 'F',
  birthDate: DateTime.utc(2024, 8, 22),
  createdAt: DateTime.utc(2024, 8, 22),
);

final _status = VaccinationStatusResult(
  petId: 'pet-1',
  summary: const VaccinationSummary(
    upToDate: 1,
    dueSoon: 1,
    dueToday: 1,
    overdue: 1,
    notStarted: 1,
  ),
  vaccines: [
    _vaccination(1, 'Rabia', 'NotStarted', eligible: true),
    _vaccination(2, 'Panleucopenia', 'Overdue'),
    _vaccination(3, 'Triple felina', 'DueToday'),
    _vaccination(4, 'Calicivirus', 'DueSoon'),
    _vaccination(5, 'Leucemia felina', 'UpToDate', registered: true),
  ],
);

final _youngPetStatus = VaccinationStatusResult(
  petId: 'pet-1',
  summary: const VaccinationSummary(
    upToDate: 7,
    dueSoon: 0,
    dueToday: 0,
    overdue: 0,
    notStarted: 0,
  ),
  vaccines: [
    _vaccination(
      2,
      'Moquillo',
      'NotStarted',
      eligible: false,
      recommendedDueAtUtc: DateTime.utc(2026, 10, 1),
      daysUntilEligible: 40,
    ),
    _vaccination(
      1,
      'Parvovirus',
      'NotStarted',
      eligible: false,
      recommendedDueAtUtc: DateTime.utc(2026, 9, 9),
      daysUntilEligible: 18,
    ),
    _vaccination(
      3,
      'Adenovirus',
      'NotStarted',
      eligible: false,
      recommendedDueAtUtc: DateTime.utc(2026, 9, 20),
      daysUntilEligible: 29,
    ),
  ],
);

PetVaccination _vaccination(
  int vaccineId,
  String name,
  String status, {
  bool registered = false,
  bool? eligible,
  DateTime? recommendedDueAtUtc,
  int? daysUntilEligible,
}) => PetVaccination(
  petVaccinationId: registered
      ? 'vaccination-$vaccineId'
      : '00000000-0000-0000-0000-000000000000-$vaccineId',
  petId: 'pet-1',
  vaccineId: vaccineId,
  vaccineName: name,
  status: status,
  appliedAtUtc: registered ? DateTime.utc(2026, 8, 21) : null,
  nextDueAtUtc: DateTime.utc(2026, 10, 28),
  eligible: eligible,
  recommendedDueAtUtc: recommendedDueAtUtc,
  daysUntilEligible: daysUntilEligible,
);
