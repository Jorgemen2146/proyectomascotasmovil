class MatchingProfile {
  const MatchingProfile({
    required this.matchingProfileId,
    required this.petId,
    required this.isActive,
    required this.preferredBreedIds,
    required this.minimumAgeMonths,
    required this.maximumAgeMonths,
    required this.requirePedigree,
    required this.requireGenealogyValidation,
    required this.maximumEstimatedInbreedingCoefficient,
    required this.minimumCompatibilityScore,
    required this.createdAt,
    required this.allowMixedBreed,
    this.updatedAt,
    this.lookingForSex,
    this.description,
    this.availableFromUtc,
  });

  final String matchingProfileId;
  final String petId;
  final bool isActive;
  final List<int> preferredBreedIds;
  final int minimumAgeMonths;
  final int maximumAgeMonths;
  final bool requirePedigree;
  final bool requireGenealogyValidation;
  final double maximumEstimatedInbreedingCoefficient;
  final int minimumCompatibilityScore;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lookingForSex;
  final bool allowMixedBreed;
  final String? description;
  final DateTime? availableFromUtc;
}

class MatchingProfileDraft {
  const MatchingProfileDraft({
    required this.petId,
    required this.lookingForSex,
    required this.allowMixedBreed,
    required this.description,
    this.preferredBreedId,
    this.minimumAgeMonths,
    this.maximumAgeMonths,
  });

  final String petId;
  final String lookingForSex;
  final int? preferredBreedId;
  final bool allowMixedBreed;
  final int? minimumAgeMonths;
  final int? maximumAgeMonths;
  final String? description;
}

class CompatibilityBreakdown {
  const CompatibilityBreakdown({
    required this.breedScore,
    required this.ageScore,
    required this.pedigreeScore,
    required this.genealogyScore,
    this.healthScore,
  });

  final int breedScore;
  final int ageScore;
  final int pedigreeScore;
  final int genealogyScore;
  final int? healthScore;
}

class MatchingCandidate {
  const MatchingCandidate({
    required this.petId,
    required this.name,
    required this.breedId,
    required this.breedName,
    required this.sex,
    required this.ageMonths,
    required this.compatibilityScore,
    required this.compatibilityBreakdown,
    required this.genealogyStatus,
    required this.healthCompatibilityStatus,
    required this.isFavorite,
    required this.warnings,
    required this.speciesName,
    required this.relationshipStatus,
    required this.photoUrls,
    required this.disclaimer,
    this.mainPhotoUrl,
    this.pedigreeCompletenessPercentage,
    this.relationshipType,
    this.estimatedOffspringInbreedingCoefficient,
    this.color,
    this.description,
    this.relationshipDescription,
  });

  final String petId;
  final String name;
  final int breedId;
  final String breedName;
  final String sex;
  final int ageMonths;
  final String? mainPhotoUrl;
  final int compatibilityScore;
  final CompatibilityBreakdown compatibilityBreakdown;
  final double? pedigreeCompletenessPercentage;
  final String? relationshipType;
  final double? estimatedOffspringInbreedingCoefficient;
  final String genealogyStatus;
  final String healthCompatibilityStatus;
  final bool isFavorite;
  final List<String> warnings;
  final String speciesName;
  final String? color;
  final String? description;
  final String relationshipStatus;
  final String? relationshipDescription;
  final List<String> photoUrls;
  final String disclaimer;

  bool get hasKnownRelationship => relationshipStatus == 'Related';
}

class MatchingSearchFilters {
  const MatchingSearchFilters({
    required this.petId,
    this.breedId,
    this.minimumAgeMonths,
    this.maximumAgeMonths,
  });

  final String petId;
  final int? breedId;
  final int? minimumAgeMonths;
  final int? maximumAgeMonths;

  @override
  bool operator ==(Object other) =>
      other is MatchingSearchFilters &&
      other.petId == petId &&
      other.breedId == breedId &&
      other.minimumAgeMonths == minimumAgeMonths &&
      other.maximumAgeMonths == maximumAgeMonths;

  @override
  int get hashCode =>
      Object.hash(petId, breedId, minimumAgeMonths, maximumAgeMonths);
}

class PublicMatchingPet {
  const PublicMatchingPet({
    required this.petId,
    required this.name,
    required this.speciesName,
    required this.breedName,
    required this.sex,
    required this.ageMonths,
    this.mainPhotoUrl,
    this.color,
  });

  final String petId;
  final String name;
  final String speciesName;
  final String breedName;
  final String sex;
  final int ageMonths;
  final String? mainPhotoUrl;
  final String? color;
}

class MatchRequest {
  const MatchRequest({
    required this.matchRequestId,
    required this.requesterPetId,
    required this.candidatePetId,
    required this.status,
    required this.compatibilityScoreSnapshot,
    required this.estimatedInbreedingCoefficientSnapshot,
    required this.relationshipTypeSnapshot,
    required this.createdAt,
    this.message,
    this.updatedAt,
    this.respondedAt,
    this.cancelledAt,
    this.expiresAt,
    this.requesterPet,
    this.targetPet,
  });

  final String matchRequestId;
  final String requesterPetId;
  final String candidatePetId;
  final String status;
  final String? message;
  final int compatibilityScoreSnapshot;
  final double estimatedInbreedingCoefficientSnapshot;
  final String relationshipTypeSnapshot;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? respondedAt;
  final DateTime? cancelledAt;
  final DateTime? expiresAt;
  final PublicMatchingPet? requesterPet;
  final PublicMatchingPet? targetPet;
}

class SharedOwnerContact {
  const SharedOwnerContact({this.displayName, this.phoneNumber});
  final String? displayName;
  final String? phoneNumber;
}

class PetMatch {
  const PetMatch({
    required this.matchId,
    required this.pet1,
    required this.pet2,
    required this.createdAtUtc,
  });
  final String matchId;
  final PublicMatchingPet pet1;
  final PublicMatchingPet pet2;
  final DateTime createdAtUtc;
}

class PetMatchDetail {
  const PetMatchDetail({
    required this.matchId,
    required this.status,
    required this.pet1,
    required this.pet2,
    required this.pet1Owner,
    required this.pet2Owner,
    required this.createdAtUtc,
    this.breedingIntent,
  });
  final String matchId;
  final String status;
  final PublicMatchingPet pet1;
  final PublicMatchingPet pet2;
  final SharedOwnerContact pet1Owner;
  final SharedOwnerContact pet2Owner;
  final DateTime createdAtUtc;
  final BreedingIntent? breedingIntent;
}

class BreedingIntent {
  const BreedingIntent({
    required this.breedingIntentId,
    required this.matchId,
    required this.status,
    required this.createdAtUtc,
    required this.proposedByCurrentUser,
    this.notes,
    this.expectedDateUtc,
    this.acceptedAtUtc,
    this.cancelledAtUtc,
  });
  final String breedingIntentId;
  final String matchId;
  final String status;
  final String? notes;
  final DateTime? expectedDateUtc;
  final DateTime createdAtUtc;
  final DateTime? acceptedAtUtc;
  final DateTime? cancelledAtUtc;
  final bool proposedByCurrentUser;
}
