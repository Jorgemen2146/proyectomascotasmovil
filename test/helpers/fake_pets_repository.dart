import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/services/photo_picker_service.dart';
import 'package:dogplatform/features/pets/domain/entities/pet.dart';
import 'package:dogplatform/features/pets/domain/repositories/pets_repository.dart';

class FakePetsRepository implements PetsRepository {
  List<PetSummary> pets = const [];
  List<Species> species = const [];
  final Map<int, List<Breed>> breeds = {};
  List<PetPhoto> photos = const [];
  PetDetails details = samplePetDetails;
  String createdPetId = 'pet-created';

  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int uploadCalls = 0;
  int setMainPhotoCalls = 0;
  int deletePhotoCalls = 0;
  AppFailure? uploadFailure;
  final List<String> events = [];
  PetDraft? lastDraft;

  @override
  Future<Result<List<PetSummary>>> getMyPets({
    String? name,
    int? speciesId,
  }) async {
    events.add('getMyPets');
    return Result.success(pets);
  }

  @override
  Future<Result<PetDetails>> getPet(String petId) async =>
      Result.success(details);

  @override
  Future<Result<List<Species>>> getSpecies() async => Result.success(species);

  @override
  Future<Result<List<Breed>>> getBreeds(int speciesId) async =>
      Result.success(breeds[speciesId] ?? const []);

  @override
  Future<Result<String>> createPet(PetDraft draft) async {
    events.add('createPet');
    createCalls++;
    lastDraft = draft;
    return Result.success(createdPetId);
  }

  @override
  Future<Result<void>> updatePet(String petId, PetDraft draft) async {
    updateCalls++;
    lastDraft = draft;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deletePet(String petId) async {
    deleteCalls++;
    return const Result.success(null);
  }

  @override
  Future<Result<List<PetPhoto>>> getPhotos(String petId) async =>
      Result.success(photos);

  @override
  Future<Result<void>> uploadPhoto(String petId, SelectedPhoto photo) async {
    events.add('uploadPhoto');
    uploadCalls++;
    if (uploadFailure != null) return Result.failure(uploadFailure!);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deletePhoto(String petId, String photoId) async {
    deletePhotoCalls++;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setMainPhoto(String petId, String photoId) async {
    setMainPhotoCalls++;
    return const Result.success(null);
  }
}

final samplePetSummary = PetSummary(
  id: '11111111-1111-1111-1111-111111111111',
  name: 'Luna',
  speciesId: 1,
  speciesName: 'Perro',
  breedId: 10,
  breedName: 'Golden Retriever',
  sex: 'F',
  birthDate: DateTime.utc(2022, 3, 15),
  mainPhotoUrl: null,
  createdAt: DateTime.utc(2024),
);

final samplePetDetails = PetDetails(
  petId: samplePetSummary.id,
  breedId: 10,
  name: 'Luna',
  birthDate: DateTime.utc(2022, 3, 15),
  gender: 'F',
  weight: 25,
  color: 'Dorado',
  pedigreeNumber: null,
  isSterilized: true,
  description: 'Muy cariñosa',
  createdAt: DateTime.utc(2024),
);
