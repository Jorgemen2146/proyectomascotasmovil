import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/dio_exception_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/health.dart';
import '../../domain/repositories/health_repository.dart';
import '../datasources/health_remote_data_source.dart';

class HealthRepositoryImpl implements HealthRepository {
  const HealthRepositoryImpl(this._remoteDataSource);

  final HealthRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Vaccine>>> getVaccines(int speciesId) => _run(() async {
    final items = await _remoteDataSource.getVaccines(speciesId);
    return items.map((item) => item.toDomain()).toList(growable: false);
  });

  @override
  Future<Result<List<PetVaccination>>> getPetVaccinations(String petId) =>
      _run(() async {
        final items = await _remoteDataSource.getPetVaccinations(petId);
        return items.map((item) => item.toDomain()).toList(growable: false);
      });

  @override
  Future<Result<VaccinationStatusResult>> getVaccinationStatus(String petId) =>
      _run(
        () async =>
            (await _remoteDataSource.getVaccinationStatus(petId)).toDomain(),
      );

  @override
  Future<Result<void>> createVaccination(
    String petId,
    VaccinationDraft draft,
  ) => _run(() => _remoteDataSource.createVaccination(petId, draft));

  @override
  Future<Result<void>> updateVaccination(
    String petId,
    String petVaccinationId,
    VaccinationDraft draft,
  ) => _run(
    () => _remoteDataSource.updateVaccination(petId, petVaccinationId, draft),
  );

  @override
  Future<Result<void>> deleteVaccination(
    String petId,
    String petVaccinationId,
  ) => _run(() => _remoteDataSource.deleteVaccination(petId, petVaccinationId));

  Future<Result<T>> _run<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } on DioException catch (error) {
      return Result.failure(_mapHealthFailure(error));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }
}

AppFailure _mapHealthFailure(DioException error) {
  final mapped = mapExceptionToFailure(mapDioExceptionToAppException(error));
  final data = error.response?.data;
  final code = data is Map ? data['code']?.toString() : null;
  if (code == 'VACCINE_SPECIES_MISMATCH') {
    return const ValidationFailure(
      'Esta vacuna no corresponde a la especie de la mascota.',
    );
  }
  if (error.response?.statusCode == 404) {
    if (code == 'Vaccination.PetNotFound') {
      return ServerFailure(
        'No se encontró la mascota.',
        statusCode: 404,
        errorCode: code,
      );
    }
    return ServerFailure(
      data is Map && data['description'] != null
          ? data['description'].toString()
          : 'No se encontró el registro de vacuna.',
      statusCode: 404,
      errorCode: code,
    );
  }
  if (mapped is NetworkFailure) {
    return const NetworkFailure(
      'No pudimos conectarnos. Revisa tu conexión e intenta otra vez.',
    );
  }
  return mapped;
}
