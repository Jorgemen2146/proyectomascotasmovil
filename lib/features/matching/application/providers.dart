import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/result/result.dart';
import '../data/datasources/matching_remote_data_source.dart';
import '../data/repositories/matching_repository_impl.dart';
import '../domain/entities/matching.dart';
import '../domain/repositories/matching_repository.dart';

final matchingRemoteDataSourceProvider = Provider<MatchingRemoteDataSource>((
  ref,
) {
  return MatchingRemoteDataSource(ref.read(gatewayDioProvider));
});

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  return MatchingRepositoryImpl(ref.read(matchingRemoteDataSourceProvider));
});

final selectedMatchingPetIdProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

final matchingProfileProvider = FutureProvider.autoDispose
    .family<MatchingProfile?, String>((ref, petId) async {
      return _unwrap(
        await ref.read(matchingRepositoryProvider).getProfile(petId),
      );
    });

final matchingSearchProvider = FutureProvider.autoDispose
    .family<List<MatchingCandidate>, MatchingSearchFilters>((
      ref,
      filters,
    ) async {
      return _unwrap(
        await ref.read(matchingRepositoryProvider).search(filters),
      );
    });

typedef MatchingCandidateKey = ({String sourcePetId, String candidatePetId});
final matchingCandidateProvider = FutureProvider.autoDispose
    .family<MatchingCandidate, MatchingCandidateKey>((ref, key) async {
      return _unwrap(
        await ref
            .read(matchingRepositoryProvider)
            .getCandidate(key.sourcePetId, key.candidatePetId),
      );
    });

final incomingRequestsProvider = FutureProvider.autoDispose<List<MatchRequest>>(
  (ref) async {
    return _unwrap(
      await ref.read(matchingRepositoryProvider).getIncoming(status: 'Pending'),
    );
  },
);

final outgoingRequestsProvider = FutureProvider.autoDispose<List<MatchRequest>>(
  (ref) async {
    return _unwrap(
      await ref.read(matchingRepositoryProvider).getOutgoing(status: 'Pending'),
    );
  },
);

final matchesProvider = FutureProvider.autoDispose<List<PetMatch>>((ref) async {
  return _unwrap(await ref.read(matchingRepositoryProvider).getMatches());
});

final matchDetailProvider = FutureProvider.autoDispose
    .family<PetMatchDetail, String>((ref, matchId) async {
      return _unwrap(
        await ref.read(matchingRepositoryProvider).getMatch(matchId),
      );
    });

final breedingIntentProvider = FutureProvider.autoDispose
    .family<BreedingIntent?, String>((ref, matchId) async {
      final detail = await ref.watch(matchDetailProvider(matchId).future);
      if (detail.breedingIntent == null) return null;
      return _unwrap(
        await ref.read(matchingRepositoryProvider).getBreedingIntent(matchId),
      );
    });

class MatchingController extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false;

  Future<Result<MatchingProfile>> createProfile(MatchingProfileDraft draft) =>
      _mutate(
        () => ref.read(matchingRepositoryProvider).createProfile(draft),
        onSuccess: (_) {
          ref.invalidate(matchingProfileProvider(draft.petId));
          ref.invalidate(matchingSearchProvider);
        },
      );

  Future<Result<MatchRequest>> sendRequest({
    required String petId,
    required String candidatePetId,
    String? message,
  }) => _mutate(
    () => ref
        .read(matchingRepositoryProvider)
        .sendRequest(
          petId: petId,
          candidatePetId: candidatePetId,
          message: message,
        ),
    onSuccess: (_) => ref.invalidate(outgoingRequestsProvider),
  );

  Future<Result<MatchRequest>> acceptRequest(
    String requestId, {
    required bool sharePhoneNumber,
  }) => _mutate(
    () => ref
        .read(matchingRepositoryProvider)
        .acceptRequest(requestId, sharePhoneNumber: sharePhoneNumber),
    onSuccess: (_) {
      ref.invalidate(incomingRequestsProvider);
      ref.invalidate(matchesProvider);
    },
  );

  Future<Result<MatchRequest>> rejectRequest(String requestId) => _mutate(
    () => ref.read(matchingRepositoryProvider).rejectRequest(requestId),
    onSuccess: (_) => ref.invalidate(incomingRequestsProvider),
  );

  Future<Result<MatchRequest>> cancelRequest(String requestId) => _mutate(
    () => ref.read(matchingRepositoryProvider).cancelRequest(requestId),
    onSuccess: (_) => ref.invalidate(outgoingRequestsProvider),
  );

  Future<Result<BreedingIntent>> proposeBreedingIntent(
    String matchId, {
    String? notes,
    DateTime? expectedDateUtc,
  }) => _mutate(
    () => ref
        .read(matchingRepositoryProvider)
        .proposeBreedingIntent(
          matchId,
          notes: notes,
          expectedDateUtc: expectedDateUtc,
        ),
    onSuccess: (_) => _refreshBreedingIntent(matchId),
  );

  Future<Result<BreedingIntent>> acceptBreedingIntent(
    String matchId,
    String intentId,
  ) => _mutate(
    () => ref.read(matchingRepositoryProvider).acceptBreedingIntent(intentId),
    onSuccess: (_) {
      _refreshBreedingIntent(matchId);
      ref.invalidate(matchesProvider);
    },
  );

  Future<Result<BreedingIntent>> cancelBreedingIntent(
    String matchId,
    String intentId,
  ) => _mutate(
    () => ref.read(matchingRepositoryProvider).cancelBreedingIntent(intentId),
    onSuccess: (_) => _refreshBreedingIntent(matchId),
  );

  void _refreshBreedingIntent(String matchId) {
    ref.invalidate(matchDetailProvider(matchId));
  }

  Future<Result<T>> _mutate<T>(
    Future<Result<T>> Function() operation, {
    required void Function(T value) onSuccess,
  }) async {
    if (state) {
      return const Result.failure(
        ValidationFailure('Hay una operación en curso.'),
      );
    }
    state = true;
    final result = await operation();
    state = false;
    final value = result.valueOrNull;
    if (value != null) onSuccess(value);
    return result;
  }
}

final matchingControllerProvider =
    AutoDisposeNotifierProvider<MatchingController, bool>(
      MatchingController.new,
    );

T _unwrap<T>(Result<T> result) => result.when(
  success: (value) => value,
  failure: (failure) => throw MatchingFeatureException(failure),
);

class MatchingFeatureException implements Exception {
  const MatchingFeatureException(this.failure);
  final AppFailure failure;
  @override
  String toString() => failure.message;
}
