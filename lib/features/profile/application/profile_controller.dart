import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../authentication/application/auth_state_controller.dart';
import '../../authentication/application/providers.dart';
import '../../authentication/domain/entities/user.dart';

class ProfileController extends AutoDisposeAsyncNotifier<User> {
  @override
  Future<User> build() async {
    final result = await ref.read(authRepositoryProvider).getCurrentUser();
    return result.when(
      success: (user) => user,
      failure: (failure) => throw ProfileException(failure),
    );
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .updateProfile(
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
        );
    return result.when(
      success: (user) {
        state = AsyncData(user);
        ref.read(authStateControllerProvider.notifier).replaceUser(user);
        return true;
      },
      failure: (failure) {
        state = AsyncError(ProfileException(failure), StackTrace.current);
        return false;
      },
    );
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
