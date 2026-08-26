import 'package:dio/dio.dart';

import '../../../../core/constants/api_paths.dart';
import '../../domain/entities/matching.dart';
import '../dto/matching_dtos.dart';

class MatchingRemoteDataSource {
  const MatchingRemoteDataSource(this._dio);
  final Dio _dio;

  Future<MatchingProfileDto> getProfile(String petId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.matchingProfiles}/$petId',
    );
    return MatchingProfileDto.fromJson(response.data!);
  }

  Future<MatchingProfileDto> createProfile(MatchingProfileDraft draft) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.matchingProfiles,
      data: {
        'petId': draft.petId,
        'isActive': true,
        'preferredBreedIds': draft.preferredBreedId == null
            ? <int>[]
            : [draft.preferredBreedId],
        'minimumAgeMonths': draft.minimumAgeMonths ?? 12,
        'maximumAgeMonths': draft.maximumAgeMonths ?? 84,
        'requirePedigree': false,
        'requireGenealogyValidation': true,
        'maximumEstimatedInbreedingCoefficient': 0.125,
        'minimumCompatibilityScore': 60,
        'lookingForSex': draft.lookingForSex,
        'allowMixedBreed': draft.allowMixedBreed,
        'description': draft.description,
        'availableFromUtc': null,
      },
    );
    return MatchingProfileDto.fromJson(response.data!);
  }

  Future<List<MatchingCandidateDto>> search(
    MatchingSearchFilters filters,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.matchingSearch,
      queryParameters: {
        'petId': filters.petId,
        'pageNumber': 1,
        'pageSize': 50,
        if (filters.breedId != null) 'breedId': filters.breedId,
        if (filters.minimumAgeMonths != null)
          'minAgeMonths': filters.minimumAgeMonths,
        if (filters.maximumAgeMonths != null)
          'maxAgeMonths': filters.maximumAgeMonths,
      },
    );
    return pagedItems(response.data!, MatchingCandidateDto.fromJson);
  }

  Future<MatchingCandidateDto> getCandidate(
    String sourcePetId,
    String candidatePetId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.matchingPets}/$candidatePetId',
      queryParameters: {'sourcePetId': sourcePetId},
    );
    return MatchingCandidateDto.fromJson(response.data!);
  }

  Future<MatchRequestDto> sendRequest({
    required String petId,
    required String candidatePetId,
    String? message,
    bool sharePhoneNumber = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.matchingRequests,
      data: {
        'petId': petId,
        'candidatePetId': candidatePetId,
        'message': _nullable(message),
        'sharePhoneNumber': sharePhoneNumber,
      },
    );
    return MatchRequestDto.fromJson(response.data!);
  }

  Future<List<MatchRequestDto>> getRequests({
    required bool incoming,
    String? status,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.matchingRequests}/${incoming ? 'incoming' : 'outgoing'}',
      queryParameters: <String, dynamic>{
        'pageNumber': 1,
        'pageSize': 50,
        'status': status,
      }..removeWhere((_, value) => value == null),
    );
    return pagedItems(response.data!, MatchRequestDto.fromJson);
  }

  Future<MatchRequestDto> requestAction(
    String requestId,
    String action, {
    bool? sharePhoneNumber,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.matchingRequests}/$requestId/$action',
      data: sharePhoneNumber == null
          ? null
          : {'sharePhoneNumber': sharePhoneNumber},
    );
    return MatchRequestDto.fromJson(response.data!);
  }

  Future<List<PetMatchDto>> getMatches() async {
    final response = await _dio.get<List<dynamic>>(ApiPaths.matchingMatches);
    return (response.data ?? const [])
        .map((item) => PetMatchDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PetMatchDetailDto> getMatch(String matchId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.matchingMatches}/$matchId',
    );
    return PetMatchDetailDto.fromJson(response.data!);
  }

  Future<BreedingIntentDto> proposeBreedingIntent(
    String matchId, {
    String? notes,
    DateTime? expectedDateUtc,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.matchingMatches}/$matchId/breeding-intents',
      data: {
        'notes': _nullable(notes),
        'expectedDateUtc': expectedDateUtc?.toUtc().toIso8601String(),
      },
    );
    return BreedingIntentDto.fromJson(response.data!);
  }

  Future<BreedingIntentDto> getBreedingIntent(String matchId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.matchingMatches}/$matchId/breeding-intent',
    );
    return BreedingIntentDto.fromJson(response.data!, matchId: matchId);
  }

  Future<BreedingIntentDto> breedingIntentAction(
    String intentId,
    String action,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.matchingBreedingIntents}/$intentId/$action',
    );
    return BreedingIntentDto.fromJson(response.data!);
  }
}

String? _nullable(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
