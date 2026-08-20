// ignore_for_file: prefer_initializing_formals, use_null_aware_elements

import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_paths.dart';
import '../../../../core/network/gateway_url_resolver.dart';
import '../../domain/entities/pet.dart';
import '../dto/pet_dtos.dart';

class PetsRemoteDataSource {
  PetsRemoteDataSource({required Dio dio, Dio? uploadDio})
    : _dio = dio,
      _uploadDio = uploadDio ?? Dio();

  final Dio _dio;
  final Dio _uploadDio;

  Future<List<PetSummaryDto>> getMyPets({String? name, int? speciesId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.myPets,
      queryParameters: {
        'pageNumber': 1,
        'pageSize': 100,
        'sortBy': 'CreatedAt',
        'sortDirection': 'DESC',
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (speciesId != null) 'speciesId': speciesId,
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

  Future<PhotoUploadTicketDto> createPhotoUploadUrl({
    required String petId,
    required String fileName,
    required String contentType,
    required int fileSize,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.photoUploadUrl(petId),
      data: {
        'fileName': fileName,
        'contentType': contentType,
        'fileSize': fileSize,
      },
    );
    return PhotoUploadTicketDto.fromJson(response.data!);
  }

  Future<void> uploadBytes({
    required PhotoUploadTicket ticket,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final headers = <String, dynamic>{...ticket.requiredHeaders};
    final hasContentType = headers.keys.any(
      (key) => key.toLowerCase() == 'content-type',
    );
    if (!hasContentType) headers['Content-Type'] = contentType;

    final uploadClient = GatewayUrlResolver.isGatewayUrl(ticket.uploadUrl)
        ? _dio
        : _uploadDio;
    await uploadClient.request<void>(
      GatewayUrlResolver.resolve(ticket.uploadUrl),
      data: bytes,
      options: Options(method: ticket.method.toUpperCase(), headers: headers),
    );
  }

  Future<void> confirmPhoto(String petId, String objectKey) async {
    await _dio.post<Map<String, dynamic>>(
      ApiPaths.confirmPhoto(petId),
      data: {'objectKey': objectKey},
    );
  }

  Future<void> deletePhoto(String petId, String photoId) async {
    await _dio.delete<void>(ApiPaths.petPhoto(petId, photoId));
  }

  Future<void> setMainPhoto(String petId, String photoId) async {
    await _dio.put<void>(ApiPaths.mainPetPhoto(petId, photoId));
  }
}
