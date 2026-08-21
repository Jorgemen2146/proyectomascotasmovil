import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/dio_exception_mapper.dart';
import '../../../../core/network/gateway_url_resolver.dart';
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
    try {
      final items = await _remoteDataSource.getPhotos(petId);
      final photos = items
          .map((item) => item.toDomain())
          .toList(growable: false);
      if (kDebugMode) {
        debugPrint('[PET_PHOTOS] response parsed');
        for (final photo in photos) {
          debugPrint('[PET_PHOTOS] photoId=${photo.photoId}');
          debugPrint('[PET_PHOTOS] rawUrl=${photo.url}');
          debugPrint(
            '[PET_PHOTOS] resolvedUrl=${GatewayUrlResolver.resolve(photo.url)}',
          );
        }
        debugPrint('[PET_PHOTOS] building gallery');
      }
      return photos;
    } catch (exception, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[PET_PHOTOS] exception runtimeType=${exception.runtimeType}',
        );
        debugPrint('[PET_PHOTOS] exception message=$exception');
        debugPrintStack(
          label: '[PET_PHOTOS] stackTrace',
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  });

  @override
  Future<Result<void>> uploadPhoto(String petId, SelectedPhoto photo) async {
    try {
      final prepared = await preparePhotoUpload(photo);
      await _remoteDataSource.uploadPhotoBase64(
        petId,
        prepared.fileName,
        prepared.contentType,
        prepared.imageBase64,
      );
      return const Result.success(null);
    } on PhotoValidationException catch (error) {
      return Result.failure(ValidationFailure(error.message));
    } on DioException catch (error) {
      return Result.failure(_mapPhotoFailure(error));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

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

AppFailure _mapPhotoFailure(DioException error) {
  final mapped = mapExceptionToFailure(mapDioExceptionToAppException(error));
  final statusCode = error.response?.statusCode;
  if (statusCode == 400) {
    return const ValidationFailure('El formato de la imagen no es válido.');
  }
  if (statusCode == 413) {
    return const ServerFailure(
      'La imagen es demasiado grande. El tamaño máximo permitido es 10 MB.',
      statusCode: 413,
    );
  }
  if (statusCode == 403) {
    return const ServerFailure(
      'No tienes permiso para modificar esta mascota.',
      statusCode: 403,
    );
  }
  if (statusCode == 500 && mapped is ServerFailure) {
    final errorId = mapped.errorCode;
    return ServerFailure(
      errorId == null || errorId.isEmpty
          ? 'Hubo un problema al guardar la foto.'
          : 'Hubo un problema al guardar la foto. Código: $errorId',
      statusCode: 500,
      errorCode: errorId,
    );
  }
  return mapped;
}
