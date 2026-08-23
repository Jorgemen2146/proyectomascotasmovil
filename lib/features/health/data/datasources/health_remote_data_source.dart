import 'package:dio/dio.dart';

import '../../domain/entities/health.dart';
import '../dto/health_dtos.dart';

class HealthRemoteDataSource {
  const HealthRemoteDataSource({required Dio dio}) : this._internal(dio);

  const HealthRemoteDataSource._internal(this._dio);

  final Dio _dio;

  Future<List<VaccineDto>> getVaccines(int speciesId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/health/vaccines',
      queryParameters: {'speciesId': speciesId},
    );
    return (response.data ?? const [])
        .map((item) => VaccineDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<PetVaccinationDto>> getPetVaccinations(String petId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/health/pets/$petId/vaccinations',
    );
    return (response.data ?? const [])
        .map((item) => PetVaccinationDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<VaccinationStatusDto> getVaccinationStatus(String petId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/health/pets/$petId/vaccination-status',
    );
    return VaccinationStatusDto.fromJson(response.data!);
  }

  Future<void> createVaccination(String petId, VaccinationDraft draft) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/health/pets/$petId/vaccinations',
      data: CreateVaccinationRequestDto(draft).toJson(),
    );
  }

  Future<void> updateVaccination(
    String petId,
    String petVaccinationId,
    VaccinationDraft draft,
  ) async {
    await _dio.put<Map<String, dynamic>>(
      '/api/v1/health/pets/$petId/vaccinations/$petVaccinationId',
      data: UpdateVaccinationRequestDto(draft).toJson(),
    );
  }

  Future<void> deleteVaccination(String petId, String petVaccinationId) async {
    await _dio.delete<void>(
      '/api/v1/health/pets/$petId/vaccinations/$petVaccinationId',
    );
  }
}
