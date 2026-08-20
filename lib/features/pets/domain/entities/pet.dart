class PetSummary {
  const PetSummary({
    required this.id,
    required this.name,
    required this.speciesId,
    required this.speciesName,
    required this.breedId,
    required this.breedName,
    required this.sex,
    required this.createdAt,
    this.birthDate,
    this.mainPhotoUrl,
    this.updatedAt,
  });

  final String id;
  final String name;
  final int speciesId;
  final String speciesName;
  final int breedId;
  final String breedName;
  final String sex;
  final DateTime? birthDate;
  final String? mainPhotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  int? get ageYears {
    final birth = birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    var years = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }
}

class PetDetails {
  const PetDetails({
    required this.petId,
    required this.breedId,
    required this.name,
    required this.gender,
    required this.isSterilized,
    required this.createdAt,
    this.birthDate,
    this.weight,
    this.color,
    this.pedigreeNumber,
    this.description,
    this.updatedAt,
  });

  final String petId;
  final int breedId;
  final String name;
  final DateTime? birthDate;
  final String gender;
  final double? weight;
  final String? color;
  final String? pedigreeNumber;
  final bool isSterilized;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

class PetDraft {
  const PetDraft({
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.weight,
    required this.color,
    required this.pedigreeNumber,
    required this.isSterilized,
    required this.description,
    this.breedId,
  });

  final int? breedId;
  final String name;
  final DateTime? birthDate;
  final String gender;
  final double? weight;
  final String? color;
  final String? pedigreeNumber;
  final bool isSterilized;
  final String? description;
}

class Species {
  const Species({required this.speciesId, required this.name});
  final int speciesId;
  final String name;
}

class Breed {
  const Breed({
    required this.breedId,
    required this.speciesId,
    required this.name,
  });
  final int breedId;
  final int speciesId;
  final String name;
}

class PetPhoto {
  const PetPhoto({
    required this.photoId,
    required this.petId,
    required this.url,
    required this.isMain,
    required this.createdAt,
  });

  final String photoId;
  final String petId;
  final String url;
  final bool isMain;
  final DateTime createdAt;
}

class PhotoUploadTicket {
  const PhotoUploadTicket({
    required this.objectKey,
    required this.uploadUrl,
    required this.expiresAtUtc,
    required this.requiredHeaders,
    this.method = 'PUT',
  });

  final String objectKey;
  final String uploadUrl;
  final DateTime expiresAtUtc;
  final Map<String, String> requiredHeaders;
  final String method;
}
