import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/result/result.dart';
import '../data/datasources/health_remote_data_source.dart';
import '../data/repositories/health_repository_impl.dart';
import '../domain/entities/health.dart';
import '../domain/repositories/health_repository.dart';

final healthRemoteDataSourceProvider = Provider<HealthRemoteDataSource>((ref) {
  return HealthRemoteDataSource(dio: ref.read(gatewayDioProvider));
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepositoryImpl(ref.read(healthRemoteDataSourceProvider));
});

final vaccinesBySpeciesProvider = FutureProvider.autoDispose
    .family<List<Vaccine>, int>((ref, speciesId) async {
      return _unwrap(
        await ref.read(healthRepositoryProvider).getVaccines(speciesId),
      );
    });

final petVaccinationsProvider = FutureProvider.autoDispose
    .family<List<PetVaccination>, String>((ref, petId) async {
      return _unwrap(
        await ref.read(healthRepositoryProvider).getPetVaccinations(petId),
      );
    });

final vaccinationStatusProvider = FutureProvider.autoDispose
    .family<VaccinationStatusResult, String>((ref, petId) async {
      return _unwrap(
        await ref.read(healthRepositoryProvider).getVaccinationStatus(petId),
      );
    });

class VaccinationMutationController extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false;

  Future<Result<void>> create(String petId, VaccinationDraft draft) => _mutate(
    petId,
    () => ref.read(healthRepositoryProvider).createVaccination(petId, draft),
  );

  Future<Result<void>> update(
    String petId,
    String petVaccinationId,
    VaccinationDraft draft,
  ) => _mutate(
    petId,
    () => ref
        .read(healthRepositoryProvider)
        .updateVaccination(petId, petVaccinationId, draft),
  );

  Future<Result<void>> delete(String petId, String petVaccinationId) => _mutate(
    petId,
    () => ref
        .read(healthRepositoryProvider)
        .deleteVaccination(petId, petVaccinationId),
  );

  Future<Result<void>> _mutate(
    String petId,
    Future<Result<void>> Function() operation,
  ) async {
    if (state) {
      return const Result.failure(UnknownFailure('Operación en curso.'));
    }
    state = true;
    final result = await operation();
    state = false;
    if (result.isSuccess) {
      ref.invalidate(petVaccinationsProvider(petId));
      ref.invalidate(vaccinationStatusProvider(petId));
    }
    return result;
  }
}

final vaccinationMutationControllerProvider =
    AutoDisposeNotifierProvider<VaccinationMutationController, bool>(
      VaccinationMutationController.new,
    );

T _unwrap<T>(Result<T> result) => result.when(
  success: (value) => value,
  failure: (failure) => throw HealthFeatureException(failure),
);

class HealthFeatureException implements Exception {
  const HealthFeatureException(this.failure);
  final AppFailure failure;
  @override
  String toString() => failure.message;
}
