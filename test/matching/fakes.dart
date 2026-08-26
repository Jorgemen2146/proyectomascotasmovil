import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/matching/domain/entities/matching.dart';
import 'package:dogplatform/features/matching/domain/repositories/matching_repository.dart';

class FakeMatchingRepository implements MatchingRepository {
  MatchingProfile? profile;
  List<MatchingCandidate> candidates = [];
  MatchingCandidate? candidate;
  List<MatchRequest> incoming = [];
  List<MatchRequest> outgoing = [];
  List<PetMatch> matches = [];
  PetMatchDetail? matchDetail;
  BreedingIntent? breedingIntent;
  final calls = <String>[];
  MatchingProfileDraft? lastProfileDraft;
  MatchingSearchFilters? lastSearchFilters;
  String? lastMessage;
  bool? lastSharePhone;

  @override
  Future<Result<MatchingProfile?>> getProfile(String petId) async =>
      Result.success(profile);

  @override
  Future<Result<MatchingProfile>> createProfile(
    MatchingProfileDraft draft,
  ) async {
    calls.add('createProfile');
    lastProfileDraft = draft;
    profile = sampleProfile;
    return Result.success(sampleProfile);
  }

  @override
  Future<Result<List<MatchingCandidate>>> search(
    MatchingSearchFilters filters,
  ) async {
    calls.add('search');
    lastSearchFilters = filters;
    return Result.success(candidates);
  }

  @override
  Future<Result<MatchingCandidate>> getCandidate(
    String sourcePetId,
    String candidatePetId,
  ) async => Result.success(candidate ?? sampleCandidate);

  @override
  Future<Result<MatchRequest>> sendRequest({
    required String petId,
    required String candidatePetId,
    String? message,
    bool sharePhoneNumber = false,
  }) async {
    calls.add('send');
    lastMessage = message;
    lastSharePhone = sharePhoneNumber;
    return Result.success(sampleRequest);
  }

  @override
  Future<Result<List<MatchRequest>>> getIncoming({String? status}) async =>
      Result.success(incoming);
  @override
  Future<Result<List<MatchRequest>>> getOutgoing({String? status}) async =>
      Result.success(outgoing);

  @override
  Future<Result<MatchRequest>> acceptRequest(
    String requestId, {
    required bool sharePhoneNumber,
  }) async {
    calls.add('accept');
    lastSharePhone = sharePhoneNumber;
    return Result.success(sampleRequest);
  }

  @override
  Future<Result<MatchRequest>> rejectRequest(String requestId) async {
    calls.add('reject');
    return Result.success(sampleRequest);
  }

  @override
  Future<Result<MatchRequest>> cancelRequest(String requestId) async {
    calls.add('cancel');
    return Result.success(sampleRequest);
  }

  @override
  Future<Result<List<PetMatch>>> getMatches() async => Result.success(matches);
  @override
  Future<Result<PetMatchDetail>> getMatch(String matchId) async {
    calls.add('getMatch');
    return Result.success(
      matchDetail ?? _matchDetailWithIntent(sampleMatchDetail, breedingIntent),
    );
  }

  @override
  Future<Result<BreedingIntent?>> getBreedingIntent(String matchId) async {
    calls.add('getIntent');
    return Result.success(breedingIntent);
  }

  @override
  Future<Result<BreedingIntent>> proposeBreedingIntent(
    String matchId, {
    String? notes,
    DateTime? expectedDateUtc,
  }) async {
    calls.add('propose');
    breedingIntent = sampleIntent;
    return Result.success(sampleIntent);
  }

  @override
  Future<Result<BreedingIntent>> acceptBreedingIntent(String intentId) async {
    calls.add('acceptIntent');
    breedingIntent = sampleAgreedIntent;
    return Result.success(sampleAgreedIntent);
  }

  @override
  Future<Result<BreedingIntent>> cancelBreedingIntent(String intentId) async {
    calls.add('cancelIntent');
    breedingIntent = sampleCancelledIntent;
    return Result.success(sampleCancelledIntent);
  }
}

final sampleProfile = MatchingProfile(
  matchingProfileId: 'profile-1',
  petId: 'mine',
  isActive: true,
  preferredBreedIds: const [1],
  minimumAgeMonths: 12,
  maximumAgeMonths: 84,
  requirePedigree: false,
  requireGenealogyValidation: true,
  maximumEstimatedInbreedingCoefficient: .125,
  minimumCompatibilityScore: 60,
  createdAt: DateTime.utc(2026),
  lookingForSex: 'F',
  allowMixedBreed: true,
  description: 'Perfil público',
);

final sampleCandidate = MatchingCandidate(
  petId: 'candidate',
  name: 'Luna',
  breedId: 1,
  breedName: 'Golden Retriever',
  sex: 'F',
  ageMonths: 36,
  mainPhotoUrl: '/photos/luna.jpg',
  compatibilityScore: 91,
  compatibilityBreakdown: const CompatibilityBreakdown(
    breedScore: 20,
    ageScore: 20,
    pedigreeScore: 20,
    genealogyScore: 20,
  ),
  pedigreeCompletenessPercentage: 90,
  relationshipType: 'Cousin',
  genealogyStatus: 'Validated',
  healthCompatibilityStatus: 'Compatible',
  isFavorite: false,
  warnings: const ['Related'],
  speciesName: 'Perro',
  color: 'Dorado',
  description: 'Cariñosa',
  relationshipStatus: 'Related',
  relationshipDescription: 'Primos registrados',
  photoUrls: const ['/photos/luna.jpg'],
  disclaimer: 'Evaluación informativa.',
  hasPedigree: true,
);

const requesterPet = PublicMatchingPet(
  petId: 'mine',
  name: 'Andrea',
  speciesName: 'Gato',
  breedName: 'Mestizo',
  sex: 'M',
  ageMonths: 24,
);
const targetPet = PublicMatchingPet(
  petId: 'candidate',
  name: 'Luna',
  speciesName: 'Gato',
  breedName: 'Mestizo',
  sex: 'F',
  ageMonths: 30,
);

final sampleRequest = MatchRequest(
  matchRequestId: 'request-1',
  requesterPetId: 'mine',
  candidatePetId: 'candidate',
  status: 'Pending',
  message: 'Hola',
  compatibilityScoreSnapshot: 90,
  estimatedInbreedingCoefficientSnapshot: 0,
  relationshipTypeSnapshot: 'UnrelatedWithinKnownPedigree',
  createdAt: DateTime.utc(2026, 8, 25),
  requesterPet: requesterPet,
  targetPet: targetPet,
);

final sampleMatchDetail = PetMatchDetail(
  matchId: 'match-1',
  status: 'Accepted',
  pet1: requesterPet,
  pet2: targetPet,
  pet1Owner: const SharedOwnerContact(
    displayName: 'Jorge',
    phoneNumber: '+51 999 000 000',
  ),
  pet2Owner: const SharedOwnerContact(displayName: 'Ana'),
  createdAtUtc: DateTime.utc(2026, 8, 25),
);

final sampleIntent = BreedingIntent(
  breedingIntentId: 'intent-1',
  matchId: 'match-1',
  status: 'Proposed',
  notes: 'Posible camada',
  createdAtUtc: DateTime.utc(2026, 8, 25),
  proposedByCurrentUser: true,
);
final sampleAgreedIntent = BreedingIntent(
  breedingIntentId: 'intent-1',
  matchId: 'match-1',
  status: 'Agreed',
  createdAtUtc: DateTime.utc(2026, 8, 25),
  acceptedAtUtc: DateTime.utc(2026, 8, 26),
  proposedByCurrentUser: true,
);
final sampleCancelledIntent = BreedingIntent(
  breedingIntentId: 'intent-1',
  matchId: 'match-1',
  status: 'Cancelled',
  createdAtUtc: DateTime.utc(2026, 8, 25),
  cancelledAtUtc: DateTime.utc(2026, 8, 26),
  proposedByCurrentUser: true,
);

final sampleReceivedIntent = BreedingIntent(
  breedingIntentId: 'intent-1',
  matchId: 'match-1',
  status: 'Proposed',
  notes: 'Posible camada',
  expectedDateUtc: DateTime.utc(2026, 11, 15),
  createdAtUtc: DateTime.utc(2026, 8, 25),
  proposedByCurrentUser: false,
);

final sampleCompletedIntent = BreedingIntent(
  breedingIntentId: 'intent-1',
  matchId: 'match-1',
  status: 'Completed',
  createdAtUtc: DateTime.utc(2026, 8, 25),
  proposedByCurrentUser: true,
);

PetMatchDetail _matchDetailWithIntent(
  PetMatchDetail detail,
  BreedingIntent? intent,
) => PetMatchDetail(
  matchId: detail.matchId,
  status: detail.status,
  pet1: detail.pet1,
  pet2: detail.pet2,
  pet1Owner: detail.pet1Owner,
  pet2Owner: detail.pet2Owner,
  createdAtUtc: detail.createdAtUtc,
  breedingIntent: intent,
);
