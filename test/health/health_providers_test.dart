import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/health/application/providers.dart';
import 'package:dogplatform/features/health/domain/entities/health.dart';
import 'package:dogplatform/features/health/domain/repositories/health_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final mutation in ['create', 'update', 'delete']) {
    test('$mutation invalida historial y estado de la mascota', () async {
      final repository = _FakeHealthRepository();
      final container = ProviderContainer(
        overrides: [healthRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final historySubscription = container.listen(
        petVaccinationsProvider('pet-1'),
        (_, _) {},
      );
      final statusSubscription = container.listen(
        vaccinationStatusProvider('pet-1'),
        (_, _) {},
      );
      addTearDown(historySubscription.close);
      addTearDown(statusSubscription.close);
      await container.read(petVaccinationsProvider('pet-1').future);
      await container.read(vaccinationStatusProvider('pet-1').future);

      final controller = container.read(
        vaccinationMutationControllerProvider.notifier,
      );
      switch (mutation) {
        case 'create':
          await controller.create('pet-1', _draft);
        case 'update':
          await controller.update('pet-1', 'vaccination-1', _draft);
        case 'delete':
          await controller.delete('pet-1', 'vaccination-1');
      }
      await container.read(petVaccinationsProvider('pet-1').future);
      await container.read(vaccinationStatusProvider('pet-1').future);

      expect(repository.historyCalls, 2);
      expect(repository.statusCalls, 2);
      expect(repository.mutations, [mutation]);
    });
  }
}

class _FakeHealthRepository implements HealthRepository {
  int historyCalls = 0;
  int statusCalls = 0;
  final List<String> mutations = [];

  @override
  Future<Result<void>> createVaccination(
    String petId,
    VaccinationDraft draft,
  ) async {
    mutations.add('create');
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deleteVaccination(
    String petId,
    String petVaccinationId,
  ) async {
    mutations.add('delete');
    return const Result.success(null);
  }

  @override
  Future<Result<List<PetVaccination>>> getPetVaccinations(String petId) async {
    historyCalls++;
    return const Result.success([]);
  }

  @override
  Future<Result<VaccinationStatusResult>> getVaccinationStatus(
    String petId,
  ) async {
    statusCalls++;
    return Result.success(
      VaccinationStatusResult(
        petId: petId,
        summary: const VaccinationSummary(
          upToDate: 0,
          dueSoon: 0,
          dueToday: 0,
          overdue: 0,
          notStarted: 0,
        ),
        vaccines: const [],
      ),
    );
  }

  @override
  Future<Result<List<Vaccine>>> getVaccines(int speciesId) async =>
      const Result.success([]);

  @override
  Future<Result<void>> updateVaccination(
    String petId,
    String petVaccinationId,
    VaccinationDraft draft,
  ) async {
    mutations.add('update');
    return const Result.success(null);
  }
}

final _draft = VaccinationDraft(
  vaccineId: 1,
  doseNumber: 1,
  appliedAtUtc: DateTime.utc(2026, 8, 22),
);
