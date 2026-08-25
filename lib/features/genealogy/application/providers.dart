import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/result/result.dart';
import '../data/datasources/genealogy_remote_data_source.dart';
import '../data/repositories/genealogy_repository_impl.dart';
import '../domain/entities/genealogy.dart';
import '../domain/repositories/genealogy_repository.dart';

typedef GenealogyTreeQuery = ({String petId, int generations});
typedef GenealogyInvitationsQuery = ({String direction, String? status});
final genealogyRemoteDataSourceProvider = Provider<GenealogyRemoteDataSource>(
  (ref) => GenealogyRemoteDataSource(dio: ref.read(gatewayDioProvider)),
);
final genealogyRepositoryProvider = Provider<GenealogyRepository>(
  (ref) => GenealogyRepositoryImpl(ref.read(genealogyRemoteDataSourceProvider)),
);
final genealogyTreeProvider = FutureProvider.autoDispose
    .family<GenealogyTree, GenealogyTreeQuery>(
      (ref, q) async => _unwrap(
        await ref
            .read(genealogyRepositoryProvider)
            .getTree(petId: q.petId, generations: q.generations),
      ),
    );
final genealogyInvitationsProvider = FutureProvider.autoDispose
    .family<List<GenealogyInvitation>, GenealogyInvitationsQuery>(
      (ref, q) async => _unwrap(
        await ref
            .read(genealogyRepositoryProvider)
            .getInvitations(direction: q.direction, status: q.status),
      ),
    );
final genealogyInvitationContextProvider = FutureProvider.autoDispose
    .family<GenealogyInvitationContext, String>(
      (ref, token) async => _unwrap(
        await ref.read(genealogyRepositoryProvider).getInvitation(token),
      ),
    );

class GenealogyController extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false;
  Future<Result<GenealogyRelationship>> addParent({
    required String childPetId,
    required int generations,
    required GenealogyParentRole role,
    required String parentPetId,
  }) => _mutate(
    () => ref
        .read(genealogyRepositoryProvider)
        .addOwnParent(
          childPetId: childPetId,
          parentPetId: parentPetId,
          role: role,
        ),
    onSuccess: () {
      ref.invalidate(
        genealogyTreeProvider((petId: childPetId, generations: generations)),
      );
    },
  );
  Future<Result<GenealogyInvitationCreated>> createInvitation({
    required String childPetId,
    required GenealogyParentRole role,
    required String ownerEmail,
  }) => _mutate(
    () => ref
        .read(genealogyRepositoryProvider)
        .createInvitation(
          childPetId: childPetId,
          role: role,
          ownerEmail: ownerEmail,
        ),
    onSuccess: _invalidateInvitations,
  );
  Future<Result<void>> deleteRelationship({
    required String relationshipId,
    required String petId,
    required int generations,
  }) => _mutate(
    () => ref
        .read(genealogyRepositoryProvider)
        .deleteRelationship(relationshipId),
    onSuccess: () {
      ref.invalidate(
        genealogyTreeProvider((petId: petId, generations: generations)),
      );
    },
  );
  Future<Result<GenealogyRelationship>> acceptInvitation({
    required String token,
    required String petId,
  }) => _mutate(
    () => ref
        .read(genealogyRepositoryProvider)
        .acceptInvitation(token: token, petId: petId),
    onSuccess: () {
      _invalidateInvitations();
      ref.invalidate(genealogyInvitationContextProvider(token));
      ref.invalidate(genealogyTreeProvider);
    },
  );
  Future<Result<void>> rejectInvitation(String token) => _mutate(
    () => ref.read(genealogyRepositoryProvider).rejectInvitation(token),
    onSuccess: () {
      _invalidateInvitations();
      ref.invalidate(genealogyInvitationContextProvider(token));
    },
  );
  Future<Result<void>> cancelInvitation(String id) => _mutate(
    () => ref.read(genealogyRepositoryProvider).cancelInvitation(id),
    onSuccess: _invalidateInvitations,
  );
  void _invalidateInvitations() => ref.invalidate(genealogyInvitationsProvider);

  Future<Result<T>> _mutate<T>(
    Future<Result<T>> Function() operation, {
    required void Function() onSuccess,
  }) async {
    if (state) {
      return Result.failure(
        const ValidationFailure('Hay una operación en curso.'),
      );
    }
    state = true;
    final result = await operation();
    state = false;
    if (result.isSuccess) onSuccess();
    return result;
  }
}

final genealogyControllerProvider =
    AutoDisposeNotifierProvider<GenealogyController, bool>(
      GenealogyController.new,
    );
T _unwrap<T>(Result<T> result) =>
    result.when(success: (v) => v, failure: (f) => throw f);
