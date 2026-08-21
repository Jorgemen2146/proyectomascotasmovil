import '../../../../core/result/result.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../entities/pet.dart';

abstract class PetsRepository {
  Future<Result<List<PetSummary>>> getMyPets({String? name, int? speciesId});
  Future<Result<PetDetails>> getPet(String petId);
  Future<Result<List<Species>>> getSpecies();
  Future<Result<List<Breed>>> getBreeds(int speciesId);
  Future<Result<String>> createPet(PetDraft draft);
  Future<Result<void>> updatePet(String petId, PetDraft draft);
  Future<Result<void>> deletePet(String petId);
  Future<Result<List<PetPhoto>>> getPhotos(String petId);
  Future<Result<PetPhoto>> uploadPhoto(String petId, SelectedPhoto photo);
  Future<Result<void>> setMainPhoto(String petId, String photoId);
  Future<Result<void>> deletePhoto(String petId, String photoId);
}
