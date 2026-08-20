import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/dio_exception_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pets_repository.dart';
import '../datasources/pets_remote_data_source.dart';

class PetsRepositoryImpl implements PetsRepository {
  const PetsRepositoryImpl(this._remoteDataSource);

  final PetsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<PetSummary>>> getMyPets({String? name, int? speciesId}) =>
      _run(() async {
        final items = await _remoteDataSource.getMyPets(
          name: name,
          speciesId: speciesId,
        );
        return items.map((item) => item.toDomain()).toList(growable: false);
      });

  @override
  Future<Result<PetDetails>> getPet(String petId) =>
      _run(() async => (await _remoteDataSource.getPet(petId)).toDomain());

  @override
  Future<Result<List<Species>>> getSpecies() => _run(() async {
    final items = await _remoteDataSource.getSpecies();
    return items.map((item) => item.toDomain()).toList(growable: false);
  });

  @override
  Future<Result<List<Breed>>> getBreeds(int speciesId) => _run(() async {
    final items = await _remoteDataSource.getBreeds(speciesId);
    return items.map((item) => item.toDomain()).toList(growable: false);
  });

  @override
  Future<Result<String>> createPet(PetDraft draft) =>
      _run(() => _remoteDataSource.createPet(draft));

  @override
  Future<Result<void>> updatePet(String petId, PetDraft draft) =>
      _run(() => _remoteDataSource.updatePet(petId, draft));

  @override
  Future<Result<void>> deletePet(String petId) =>
      _run(() => _remoteDataSource.deletePet(petId));

  @override
  Future<Result<List<PetPhoto>>> getPhotos(String petId) => _run(() async {
    final items = await _remoteDataSource.getPhotos(petId);
    return items.map((item) => item.toDomain()).toList(growable: false);
  });

  @override
  Future<Result<void>> uploadPhoto(String petId, SelectedPhoto photo) =>
      _run(() async {
        final ticket = (await _remoteDataSource.createPhotoUploadUrl(
          petId: petId,
          fileName: photo.fileName,
          contentType: photo.contentType,
          fileSize: photo.fileSize,
        )).toDomain();
        final bytes = await photo.file.readAsBytes();
        await _remoteDataSource.uploadBytes(
          ticket: ticket,
          bytes: bytes,
          contentType: photo.contentType,
        );
        await _remoteDataSource.confirmPhoto(petId, ticket.objectKey);
      });

  @override
  Future<Result<void>> deletePhoto(String petId, String photoId) =>
      _run(() => _remoteDataSource.deletePhoto(petId, photoId));

  @override
  Future<Result<void>> setMainPhoto(String petId, String photoId) =>
      _run(() => _remoteDataSource.setMainPhoto(petId, photoId));

  Future<Result<T>> _run<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } on DioException catch (error) {
      return Result.failure(
        mapExceptionToFailure(mapDioExceptionToAppException(error)),
      );
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }
}
