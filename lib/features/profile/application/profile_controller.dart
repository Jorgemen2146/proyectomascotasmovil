import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/services/photo_picker_service.dart';
import '../../authentication/application/auth_state_controller.dart';
import '../../authentication/application/providers.dart';
import '../../authentication/domain/entities/user.dart';

final profilePhotoPickerProvider = Provider<PhotoPickerService>((ref) {
  return ImagePickerPhotoPickerService();
});

class ProfileUpdateOutcome {
  const ProfileUpdateOutcome({this.photoFailure, this.refreshFailure});

  final AppFailure? photoFailure;
  final AppFailure? refreshFailure;
}

class ProfileController extends AutoDisposeAsyncNotifier<User> {
  @override
  Future<User> build() async {
    final result = await ref.read(authRepositoryProvider).getCurrentUser();
    return result.when(
      success: (user) => user,
      failure: (failure) => throw ProfileException(failure),
    );
  }

  Future<ProfileUpdateOutcome?> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    SelectedPhoto? photo,
  }) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    final updated = await repository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    );
    if (updated.isFailure) {
      final failure = updated.failureOrNull!;
      state = AsyncError(ProfileException(failure), StackTrace.current);
      return null;
    }

    AppFailure? photoFailure;
    if (photo != null) {
      final uploaded = await repository.uploadProfilePhoto(photo);
      photoFailure = uploaded.failureOrNull;
    }

    final refreshed = await repository.getCurrentUser();
    if (refreshed.isFailure) {
      final failure = refreshed.failureOrNull!;
      state = AsyncError(ProfileException(failure), StackTrace.current);
      return ProfileUpdateOutcome(
        photoFailure: photoFailure,
        refreshFailure: failure,
      );
    }

    final user = refreshed.valueOrNull!;
    state = AsyncData(user);
    ref.read(authStateControllerProvider.notifier).replaceUser(user);
    return ProfileUpdateOutcome(photoFailure: photoFailure);
  }
}

final profileControllerProvider =
    AutoDisposeAsyncNotifierProvider<ProfileController, User>(
      ProfileController.new,
    );

class ProfileException implements Exception {
  const ProfileException(this.failure);
  final AppFailure failure;
  @override
  String toString() => failure.message;
}
