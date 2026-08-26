import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/dio_exception_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/matching.dart';
import '../../domain/repositories/matching_repository.dart';
import '../datasources/matching_remote_data_source.dart';

class MatchingRepositoryImpl implements MatchingRepository {
  const MatchingRepositoryImpl(this._remote);
  final MatchingRemoteDataSource _remote;

  @override
  Future<Result<MatchingProfile?>> getProfile(String petId) async {
    try {
      return Result.success((await _remote.getProfile(petId)).toDomain());
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const Result.success(null);
      return Result.failure(_failure(error));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<Result<MatchingProfile>> createProfile(MatchingProfileDraft draft) =>
      _run(() async => (await _remote.createProfile(draft)).toDomain());

  @override
  Future<Result<List<MatchingCandidate>>> search(
    MatchingSearchFilters filters,
  ) => _run(
    () async => (await _remote.search(
      filters,
    )).map((item) => item.toDomain()).toList(growable: false),
  );

  @override
  Future<Result<MatchingCandidate>> getCandidate(
    String sourcePetId,
    String candidatePetId,
  ) => _run(
    () async =>
        (await _remote.getCandidate(sourcePetId, candidatePetId)).toDomain(),
  );

  @override
  Future<Result<MatchRequest>> sendRequest({
    required String petId,
    required String candidatePetId,
    String? message,
    bool sharePhoneNumber = false,
  }) => _run(
    () async => (await _remote.sendRequest(
      petId: petId,
      candidatePetId: candidatePetId,
      message: message,
      sharePhoneNumber: sharePhoneNumber,
    )).toDomain(),
  );

  @override
  Future<Result<List<MatchRequest>>> getIncoming({String? status}) =>
      _requests(incoming: true, status: status);
  @override
  Future<Result<List<MatchRequest>>> getOutgoing({String? status}) =>
      _requests(incoming: false, status: status);

  Future<Result<List<MatchRequest>>> _requests({
    required bool incoming,
    String? status,
  }) => _run(
    () async => (await _remote.getRequests(
      incoming: incoming,
      status: status,
    )).map((item) => item.toDomain()).toList(growable: false),
  );

  @override
  Future<Result<MatchRequest>> acceptRequest(
    String requestId, {
    required bool sharePhoneNumber,
  }) => _run(
    () async => (await _remote.requestAction(
      requestId,
      'accept',
      sharePhoneNumber: sharePhoneNumber,
    )).toDomain(),
  );
  @override
  Future<Result<MatchRequest>> rejectRequest(String requestId) => _run(
    () async => (await _remote.requestAction(requestId, 'reject')).toDomain(),
  );
  @override
  Future<Result<MatchRequest>> cancelRequest(String requestId) => _run(
    () async => (await _remote.requestAction(requestId, 'cancel')).toDomain(),
  );

  @override
  Future<Result<List<PetMatch>>> getMatches() => _run(
    () async => (await _remote.getMatches())
        .map((item) => item.toDomain())
        .toList(growable: false),
  );
  @override
  Future<Result<PetMatchDetail>> getMatch(String matchId) =>
      _run(() async => (await _remote.getMatch(matchId)).toDomain());

  @override
  Future<Result<BreedingIntent?>> getBreedingIntent(String matchId) async {
    try {
      return Result.success(
        (await _remote.getBreedingIntent(matchId)).toDomain(),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const Result.success(null);
      return Result.failure(_failure(error));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<Result<BreedingIntent>> proposeBreedingIntent(
    String matchId, {
    String? notes,
    DateTime? expectedDateUtc,
  }) => _run(
    () async => (await _remote.proposeBreedingIntent(
      matchId,
      notes: notes,
      expectedDateUtc: expectedDateUtc,
    )).toDomain(),
  );
  @override
  Future<Result<BreedingIntent>> acceptBreedingIntent(String intentId) => _run(
    () async =>
        (await _remote.breedingIntentAction(intentId, 'accept')).toDomain(),
  );
  @override
  Future<Result<BreedingIntent>> cancelBreedingIntent(String intentId) => _run(
    () async =>
        (await _remote.breedingIntentAction(intentId, 'cancel')).toDomain(),
  );

  Future<Result<T>> _run<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } on DioException catch (error) {
      return Result.failure(_failure(error));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }
}

AppFailure _failure(DioException error) {
  final data = error.response?.data;
  final code = data is Map
      ? (data['code'] ?? data['errorId'] ?? data['error'])?.toString()
      : null;
  final message = switch (code?.toUpperCase()) {
    'MATCHING_REQUEST_EXISTS' => 'Ya enviaste una solicitud.',
    'MATCHING_SELF_REQUEST' =>
      'No puedes enviar una solicitud a tu propia mascota.',
    'MATCHING_NOT_COMPATIBLE' =>
      'Estas mascotas no cumplen los criterios actuales.',
    'MATCHING_MATCH_NOT_ACCEPTED' =>
      'La solicitud todavía no ha sido aceptada.',
    'MATCHING_CONTACT_NOT_SHARED' =>
      'El propietario decidió no compartir este dato.',
    'MATCHING_REQUEST_ALREADY_PROCESSED' => 'La solicitud ya fue procesada.',
    'MATCHING_BREEDING_INTENT_EXISTS' =>
      'Ya existe una intención activa para esta conexión.',
    'MATCHING_FORBIDDEN' => 'No tienes permiso para realizar esta acción.',
    _ => null,
  };
  if (error.response?.statusCode == 403) {
    return const ValidationFailure(
      'No tienes permiso para realizar esta acción.',
    );
  }
  return message == null
      ? mapExceptionToFailure(mapDioExceptionToAppException(error))
      : ValidationFailure(message);
}
