import 'package:dio/dio.dart';

import '../../../../core/constants/api_paths.dart';
import '../../domain/entities/pet.dart';
import '../dto/pet_dtos.dart';

class PetsRemoteDataSource {
  PetsRemoteDataSource({required Dio dio}) : this._internal(dio);

  PetsRemoteDataSource._internal(this._dio);

  final Dio _dio;

  Future<List<PetSummaryDto>> getMyPets({String? name, int? speciesId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.myPets,
      queryParameters: {
        'pageNumber': 1,
        'pageSize': 100,
        'sortBy': 'CreatedAt',
        'sortDirection': 'DESC',
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        'speciesId': ?speciesId,
      },
    );
    final items = (response.data?['items'] as List<dynamic>? ?? const []);
    return items
        .map((item) => PetSummaryDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PetDetailsDto> getPet(String petId) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.pet(petId));
    return PetDetailsDto.fromJson(response.data!);
  }

  Future<List<SpeciesDto>> getSpecies() async {
    final response = await _dio.get<List<dynamic>>(ApiPaths.species);
    return (response.data ?? const [])
        .map((item) => SpeciesDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<BreedDto>> getBreeds(int speciesId) async {
    final response = await _dio.get<List<dynamic>>(ApiPaths.breeds(speciesId));
    return (response.data ?? const [])
        .map((item) => BreedDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<String> createPet(PetDraft draft) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.pets,
      data: CreatePetRequestDto(draft).toJson(),
    );
    return response.data!['petId'] as String;
  }

  Future<void> updatePet(String petId, PetDraft draft) async {
    await _dio.put<Map<String, dynamic>>(
      ApiPaths.pet(petId),
      data: UpdatePetRequestDto(draft).toJson(),
    );
  }

  Future<void> deletePet(String petId) async {
    await _dio.delete<void>(ApiPaths.pet(petId));
  }

  Future<List<PetPhotoDto>> getPhotos(String petId) async {
    final response = await _dio.get<List<dynamic>>(ApiPaths.petPhotos(petId));
    return (response.data ?? const [])
        .map((item) => PetPhotoDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PetPhotoDto> uploadPhotoBase64(
    String petId,
    String fileName,
    String contentType,
    String imageBase64,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.petPhotos(petId),
      data: {
        'fileName': fileName,
        'contentType': contentType,
        'imageBase64': imageBase64,
      },
    );
    return PetPhotoDto.fromJson(response.data!);
  }

  Future<void> deletePhoto(String petId, String photoId) async {
    await _dio.delete<void>(ApiPaths.petPhoto(petId, photoId));
  }

  Future<void> setMainPhoto(String petId, String photoId) async {
    await _dio.put<void>(ApiPaths.mainPetPhoto(petId, photoId));
  }
}
