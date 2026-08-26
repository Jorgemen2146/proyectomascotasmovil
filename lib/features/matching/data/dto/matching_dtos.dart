import '../../domain/entities/matching.dart';

class MatchingProfileDto {
  const MatchingProfileDto(this.value);
  factory MatchingProfileDto.fromJson(Map<String, dynamic> json) =>
      MatchingProfileDto(
        MatchingProfile(
          matchingProfileId: json['matchingProfileId'] as String,
          petId: json['petId'] as String,
          isActive: json['isActive'] as bool,
          preferredBreedIds: _ints(json['preferredBreedIds']),
          minimumAgeMonths: json['minimumAgeMonths'] as int,
          maximumAgeMonths: json['maximumAgeMonths'] as int,
          requirePedigree: json['requirePedigree'] as bool,
          requireGenealogyValidation:
              json['requireGenealogyValidation'] as bool,
          maximumEstimatedInbreedingCoefficient:
              (json['maximumEstimatedInbreedingCoefficient'] as num).toDouble(),
          minimumCompatibilityScore: json['minimumCompatibilityScore'] as int,
          createdAt: DateTime.parse(json['createdAt'] as String),
          updatedAt: _date(json['updatedAt']),
          lookingForSex: json['lookingForSex'] as String?,
          allowMixedBreed: json['allowMixedBreed'] as bool,
          description: json['description'] as String?,
          availableFromUtc: _date(json['availableFromUtc']),
        ),
      );
  final MatchingProfile value;
  MatchingProfile toDomain() => value;
}

class MatchingCandidateDto {
  const MatchingCandidateDto(this.value);
  factory MatchingCandidateDto.fromJson(Map<String, dynamic> json) {
    final breakdown = json['compatibilityBreakdown'] as Map<String, dynamic>;
    return MatchingCandidateDto(
      MatchingCandidate(
        petId: json['petId'] as String,
        name: json['name'] as String,
        breedId: json['breedId'] as int,
        breedName: json['breedName'] as String,
        sex: json['sex'] as String,
        ageMonths: json['ageMonths'] as int,
        mainPhotoUrl: json['mainPhotoUrl'] as String?,
        compatibilityScore: json['compatibilityScore'] as int,
        compatibilityBreakdown: CompatibilityBreakdown(
          breedScore: breakdown['breedScore'] as int,
          ageScore: breakdown['ageScore'] as int,
          pedigreeScore: breakdown['pedigreeScore'] as int,
          genealogyScore: breakdown['genealogyScore'] as int,
          healthScore: breakdown['healthScore'] as int?,
        ),
        pedigreeCompletenessPercentage:
            (json['pedigreeCompletenessPercentage'] as num?)?.toDouble(),
        relationshipType: _enumName(
          json['relationshipType'],
          _relationshipTypes,
        ),
        estimatedOffspringInbreedingCoefficient:
            (json['estimatedOffspringInbreedingCoefficient'] as num?)
                ?.toDouble(),
        genealogyStatus: _enumName(json['genealogyStatus'], const [
          'Validated',
          'Unknown',
          'Unavailable',
        ])!,
        healthCompatibilityStatus: _enumName(
          json['healthCompatibilityStatus'],
          const ['Unknown', 'Compatible', 'Warning', 'Incompatible'],
        )!,
        isFavorite: json['isFavorite'] as bool,
        warnings: _strings(json['warnings']),
        speciesName: json['speciesName'] as String,
        color: json['color'] as String?,
        description: json['description'] as String?,
        relationshipStatus: json['relationshipStatus'] as String,
        relationshipDescription: json['relationshipDescription'] as String?,
        photoUrls: _strings(json['photoUrls']),
        disclaimer: json['disclaimer'] as String,
      ),
    );
  }
  final MatchingCandidate value;
  MatchingCandidate toDomain() => value;
}

class PublicMatchingPetDto {
  const PublicMatchingPetDto(this.value);
  factory PublicMatchingPetDto.fromJson(Map<String, dynamic> json) =>
      PublicMatchingPetDto(
        PublicMatchingPet(
          petId: json['petId'] as String,
          name: json['name'] as String,
          speciesName: json['speciesName'] as String,
          breedName: json['breedName'] as String,
          sex: json['sex'] as String,
          ageMonths: json['ageMonths'] as int,
          mainPhotoUrl: json['mainPhotoUrl'] as String?,
          color: json['color'] as String?,
        ),
      );
  final PublicMatchingPet value;
  PublicMatchingPet toDomain() => value;
}

class MatchRequestDto {
  const MatchRequestDto(this.value);
  factory MatchRequestDto.fromJson(Map<String, dynamic> json) =>
      MatchRequestDto(
        MatchRequest(
          matchRequestId: json['matchRequestId'] as String,
          requesterPetId: json['requesterPetId'] as String,
          candidatePetId: json['candidatePetId'] as String,
          status: _enumName(json['status'], const [
            'Pending',
            'Accepted',
            'Rejected',
            'Cancelled',
            'Expired',
          ])!,
          message: json['message'] as String?,
          compatibilityScoreSnapshot: json['compatibilityScoreSnapshot'] as int,
          estimatedInbreedingCoefficientSnapshot:
              (json['estimatedInbreedingCoefficientSnapshot'] as num)
                  .toDouble(),
          relationshipTypeSnapshot: _enumName(
            json['relationshipTypeSnapshot'],
            _relationshipTypes,
          )!,
          createdAt: DateTime.parse(json['createdAt'] as String),
          updatedAt: _date(json['updatedAt']),
          respondedAt: _date(json['respondedAt']),
          cancelledAt: _date(json['cancelledAt']),
          expiresAt: _date(json['expiresAt']),
          requesterPet: _pet(json['requesterPet']),
          targetPet: _pet(json['targetPet']),
        ),
      );
  final MatchRequest value;
  MatchRequest toDomain() => value;
}

class PetMatchDto {
  const PetMatchDto(this.value);
  factory PetMatchDto.fromJson(Map<String, dynamic> json) => PetMatchDto(
    PetMatch(
      matchId: json['matchId'] as String,
      pet1: PublicMatchingPetDto.fromJson(
        json['pet1'] as Map<String, dynamic>,
      ).toDomain(),
      pet2: PublicMatchingPetDto.fromJson(
        json['pet2'] as Map<String, dynamic>,
      ).toDomain(),
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    ),
  );
  final PetMatch value;
  PetMatch toDomain() => value;
}

class PetMatchDetailDto {
  const PetMatchDetailDto(this.value);
  factory PetMatchDetailDto.fromJson(Map<String, dynamic> json) =>
      PetMatchDetailDto(
        PetMatchDetail(
          matchId: json['matchId'] as String,
          status: json['status'] as String,
          pet1: PublicMatchingPetDto.fromJson(
            json['pet1'] as Map<String, dynamic>,
          ).toDomain(),
          pet2: PublicMatchingPetDto.fromJson(
            json['pet2'] as Map<String, dynamic>,
          ).toDomain(),
          pet1Owner: _contact(json['pet1Owner']),
          pet2Owner: _contact(json['pet2Owner']),
          createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
          breedingIntent: _breedingIntent(
            json['breedingIntent'],
            matchId: json['matchId'] as String,
          ),
        ),
      );
  final PetMatchDetail value;
  PetMatchDetail toDomain() => value;
}

class BreedingIntentDto {
  const BreedingIntentDto(this.value);
  factory BreedingIntentDto.fromJson(
    Map<String, dynamic> json, {
    String? matchId,
  }) => BreedingIntentDto(
    BreedingIntent(
      breedingIntentId: json['breedingIntentId'] as String,
      matchId:
          json['matchId'] as String? ??
          matchId ??
          (throw const FormatException('BreedingIntent sin matchId.')),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      expectedDateUtc: _date(json['expectedDateUtc']),
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      acceptedAtUtc: _date(json['acceptedAtUtc']),
      cancelledAtUtc: _date(json['cancelledAtUtc']),
      proposedByCurrentUser: json['proposedByCurrentUser'] as bool,
    ),
  );
  final BreedingIntent value;
  BreedingIntent toDomain() => value;
}

List<T> pagedItems<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) parse,
) => (json['items'] as List<dynamic>? ?? const [])
    .map((item) => parse(item as Map<String, dynamic>))
    .toList(growable: false);

PublicMatchingPet? _pet(Object? value) => value is Map<String, dynamic>
    ? PublicMatchingPetDto.fromJson(value).toDomain()
    : null;

BreedingIntent? _breedingIntent(Object? value, {required String matchId}) =>
    value is Map<String, dynamic>
    ? BreedingIntentDto.fromJson(value, matchId: matchId).toDomain()
    : null;

SharedOwnerContact _contact(Object? value) {
  final json = value as Map<String, dynamic>? ?? const {};
  return SharedOwnerContact(
    displayName: json['displayName'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
  );
}

List<int> _ints(Object? value) =>
    (value as List<dynamic>? ?? const []).cast<int>().toList(growable: false);
List<String> _strings(Object? value) => (value as List<dynamic>? ?? const [])
    .map((item) => item.toString())
    .toList(growable: false);
DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

String? _enumName(Object? value, List<String> values) {
  if (value == null) return null;
  if (value is int && value >= 0 && value < values.length) return values[value];
  return value.toString();
}

const _relationshipTypes = [
  'SamePet',
  'Parent',
  'Child',
  'FullSibling',
  'HalfSibling',
  'Grandparent',
  'Grandchild',
  'UncleOrAunt',
  'NephewOrNiece',
  'FirstCousin',
  'MoreDistantRelative',
  'UnrelatedWithinKnownPedigree',
  'UnknownDueToIncompletePedigree',
];
