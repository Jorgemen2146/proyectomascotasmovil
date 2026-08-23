import '../../../../core/result/result.dart';
import '../entities/health.dart';

abstract class HealthRepository {
  Future<Result<List<Vaccine>>> getVaccines(int speciesId);
  Future<Result<List<PetVaccination>>> getPetVaccinations(String petId);
  Future<Result<VaccinationStatusResult>> getVaccinationStatus(String petId);
  Future<Result<void>> createVaccination(String petId, VaccinationDraft draft);
  Future<Result<void>> updateVaccination(
    String petId,
    String petVaccinationId,
    VaccinationDraft draft,
  );
  Future<Result<void>> deleteVaccination(String petId, String petVaccinationId);
}
