import '../../../../core/result/result.dart';
import '../entities/matching.dart';

abstract interface class MatchingRepository {
  Future<Result<MatchingProfile?>> getProfile(String petId);
  Future<Result<MatchingProfile>> createProfile(MatchingProfileDraft draft);
  Future<Result<List<MatchingCandidate>>> search(MatchingSearchFilters filters);
  Future<Result<MatchingCandidate>> getCandidate(
    String sourcePetId,
    String candidatePetId,
  );
  Future<Result<MatchRequest>> sendRequest({
    required String petId,
    required String candidatePetId,
    String? message,
    bool sharePhoneNumber = false,
  });
  Future<Result<List<MatchRequest>>> getIncoming({String? status});
  Future<Result<List<MatchRequest>>> getOutgoing({String? status});
  Future<Result<MatchRequest>> acceptRequest(
    String requestId, {
    required bool sharePhoneNumber,
  });
  Future<Result<MatchRequest>> rejectRequest(String requestId);
  Future<Result<MatchRequest>> cancelRequest(String requestId);
  Future<Result<List<PetMatch>>> getMatches();
  Future<Result<PetMatchDetail>> getMatch(String matchId);
  Future<Result<BreedingIntent?>> getBreedingIntent(String matchId);
  Future<Result<BreedingIntent>> proposeBreedingIntent(
    String matchId, {
    String? notes,
    DateTime? expectedDateUtc,
  });
  Future<Result<BreedingIntent>> acceptBreedingIntent(String intentId);
  Future<Result<BreedingIntent>> cancelBreedingIntent(String intentId);
}
