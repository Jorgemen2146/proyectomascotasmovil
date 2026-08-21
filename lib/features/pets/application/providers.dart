import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/result/result.dart';
import '../../../core/services/photo_picker_service.dart';
import '../data/datasources/pets_remote_data_source.dart';
import '../data/repositories/pets_repository_impl.dart';
import '../domain/entities/pet.dart';
import '../domain/repositories/pets_repository.dart';

final petsRemoteDataSourceProvider = Provider<PetsRemoteDataSource>((ref) {
  return PetsRemoteDataSource(dio: ref.read(gatewayDioProvider));
});

final petsRepositoryProvider = Provider<PetsRepository>((ref) {
  return PetsRepositoryImpl(ref.read(petsRemoteDataSourceProvider));
});

final photoPickerServiceProvider = Provider<PhotoPickerService>((ref) {
  return ImagePickerPhotoPickerService();
});

final myPetsProvider = FutureProvider.autoDispose<List<PetSummary>>((
  ref,
) async {
  return _unwrap(await ref.read(petsRepositoryProvider).getMyPets());
});

final petDetailsProvider = FutureProvider.autoDispose
    .family<PetDetails, String>((ref, petId) async {
      return _unwrap(await ref.read(petsRepositoryProvider).getPet(petId));
    });

final speciesProvider = FutureProvider.autoDispose<List<Species>>((ref) async {
  return _unwrap(await ref.read(petsRepositoryProvider).getSpecies());
});

final breedsProvider = FutureProvider.autoDispose.family<List<Breed>, int>((
  ref,
  speciesId,
) async {
  return _unwrap(await ref.read(petsRepositoryProvider).getBreeds(speciesId));
});

final petPhotosProvider = FutureProvider.autoDispose
    .family<List<PetPhoto>, String>((ref, petId) async {
      return _unwrap(await ref.read(petsRepositoryProvider).getPhotos(petId));
    });

class PetSaveOutcome {
  const PetSaveOutcome({required this.petId, this.photoFailure});

  final String petId;
  final AppFailure? photoFailure;
}

class PetFormController extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false;

  Future<Result<String>> create(PetDraft draft) async {
    if (state) {
      return const Result.failure(UnknownFailure('Operación en curso.'));
    }
    state = true;
    final result = await ref.read(petsRepositoryProvider).createPet(draft);
    state = false;
    if (result.isSuccess) ref.invalidate(myPetsProvider);
    return result;
  }

  Future<Result<PetSaveOutcome>> createWithOptionalPhoto(
    PetDraft draft,
    SelectedPhoto? photo,
  ) async {
    if (state) {
      return const Result.failure(UnknownFailure('Operación en curso.'));
    }
    state = true;
    final repository = ref.read(petsRepositoryProvider);
    final created = await repository.createPet(draft);
    if (created.isFailure) {
      state = false;
      return Result.failure(created.failureOrNull!);
    }

    final petId = created.valueOrNull!;
    AppFailure? photoFailure;
    if (photo != null) {
      final uploaded = await repository.uploadPhoto(petId, photo);
      photoFailure = uploaded.failureOrNull;
    }
    ref.invalidate(myPetsProvider);
    state = false;
    return Result.success(
      PetSaveOutcome(petId: petId, photoFailure: photoFailure),
    );
  }

  Future<Result<void>> update(String petId, PetDraft draft) async {
    if (state) {
      return const Result.failure(UnknownFailure('Operación en curso.'));
    }
    state = true;
    final result = await ref
        .read(petsRepositoryProvider)
        .updatePet(petId, draft);
    state = false;
    if (result.isSuccess) {
      ref.invalidate(myPetsProvider);
      ref.invalidate(petDetailsProvider(petId));
    }
    return result;
  }

  Future<Result<PetSaveOutcome>> updateWithOptionalPhoto(
    String petId,
    PetDraft draft,
    SelectedPhoto? photo,
  ) async {
    if (state) {
      return const Result.failure(UnknownFailure('Operación en curso.'));
    }
    state = true;
    final repository = ref.read(petsRepositoryProvider);
    final updated = await repository.updatePet(petId, draft);
    if (updated.isFailure) {
      state = false;
      return Result.failure(updated.failureOrNull!);
    }

    _invalidatePet(petId);
    AppFailure? photoFailure;
    if (photo != null) {
      final uploaded = await repository.uploadPhoto(petId, photo);
      photoFailure = uploaded.failureOrNull;
      if (uploaded.isSuccess) _invalidatePet(petId);
    }
    state = false;
    return Result.success(
      PetSaveOutcome(petId: petId, photoFailure: photoFailure),
    );
  }

  Future<Result<void>> delete(String petId) async {
    if (state) {
      return const Result.failure(UnknownFailure('Operación en curso.'));
    }
    state = true;
    final result = await ref.read(petsRepositoryProvider).deletePet(petId);
    state = false;
    if (result.isSuccess) {
      ref.invalidate(myPetsProvider);
      ref.invalidate(petDetailsProvider(petId));
      ref.invalidate(petPhotosProvider(petId));
    }
    return result;
  }

  void _invalidatePet(String petId) {
    ref.invalidate(myPetsProvider);
    ref.invalidate(petDetailsProvider(petId));
    ref.invalidate(petPhotosProvider(petId));
  }
}

final petFormControllerProvider =
    AutoDisposeNotifierProvider<PetFormController, bool>(PetFormController.new);

class PetPhotoController extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false;

  Future<Result<void>> upload(String petId, SelectedPhoto photo) async {
    if (state) {
      return const Result.failure(UnknownFailure('Operación en curso.'));
    }
    state = true;
    final result = await ref
        .read(petsRepositoryProvider)
        .uploadPhoto(petId, photo);
    state = false;
    if (result.isSuccess) _invalidate(petId);
    return result;
  }

  Future<Result<void>> delete(String petId, String photoId) async {
    if (state) {
      return const Result.failure(UnknownFailure('Operación en curso.'));
    }
    state = true;
    final result = await ref
        .read(petsRepositoryProvider)
        .deletePhoto(petId, photoId);
    state = false;
    if (result.isSuccess) _invalidate(petId);
    return result;
  }

  Future<Result<void>> setMain(String petId, String photoId) async {
    if (state) {
      return const Result.failure(UnknownFailure('Operación en curso.'));
    }
    state = true;
    final result = await ref
        .read(petsRepositoryProvider)
        .setMainPhoto(petId, photoId);
    state = false;
    if (result.isSuccess) _invalidate(petId);
    return result;
  }

  void _invalidate(String petId) {
    ref.invalidate(petPhotosProvider(petId));
    ref.invalidate(petDetailsProvider(petId));
    ref.invalidate(myPetsProvider);
  }
}

final petPhotoControllerProvider =
    AutoDisposeNotifierProvider<PetPhotoController, bool>(
      PetPhotoController.new,
    );

T _unwrap<T>(Result<T> result) => result.when(
  success: (value) => value,
  failure: (failure) => throw PetFeatureException(failure),
);

class PetFeatureException implements Exception {
  const PetFeatureException(this.failure);
  final AppFailure failure;
  @override
  String toString() => failure.message;
}
