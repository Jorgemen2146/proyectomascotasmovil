import '../../domain/entities/pet.dart';

class PetSummaryDto {
  const PetSummaryDto({
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

  factory PetSummaryDto.fromJson(Map<String, dynamic> json) => PetSummaryDto(
    id: json['id'] as String,
    name: json['name'] as String,
    speciesId: (json['speciesId'] as num).toInt(),
    speciesName: json['speciesName'] as String,
    breedId: (json['breedId'] as num).toInt(),
    breedName: json['breedName'] as String,
    sex: json['sex'] as String,
    birthDate: _date(json['birthDate']),
    mainPhotoUrl: json['mainPhotoUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: _date(json['updatedAt']),
  );

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

  PetSummary toDomain() => PetSummary(
    id: id,
    name: name,
    speciesId: speciesId,
    speciesName: speciesName,
    breedId: breedId,
    breedName: breedName,
    sex: sex,
    birthDate: birthDate,
    mainPhotoUrl: mainPhotoUrl,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class PetDetailsDto {
  const PetDetailsDto({
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

  factory PetDetailsDto.fromJson(Map<String, dynamic> json) => PetDetailsDto(
    petId: json['petId'] as String,
    breedId: (json['breedId'] as num).toInt(),
    name: json['name'] as String,
    birthDate: _date(json['birthDate']),
    gender: json['gender'] as String,
    weight: (json['weight'] as num?)?.toDouble(),
    color: json['color'] as String?,
    pedigreeNumber: json['pedigreeNumber'] as String?,
    isSterilized: json['isSterilized'] as bool,
    description: json['description'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: _date(json['updatedAt']),
  );

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

  PetDetails toDomain() => PetDetails(
    petId: petId,
    breedId: breedId,
    name: name,
    birthDate: birthDate,
    gender: gender,
    weight: weight,
    color: color,
    pedigreeNumber: pedigreeNumber,
    isSterilized: isSterilized,
    description: description,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class SpeciesDto {
  const SpeciesDto({required this.speciesId, required this.name});
  factory SpeciesDto.fromJson(Map<String, dynamic> json) => SpeciesDto(
    speciesId: (json['speciesId'] as num).toInt(),
    name: json['name'] as String,
  );
  final int speciesId;
  final String name;
  Species toDomain() => Species(speciesId: speciesId, name: name);
}

class BreedDto {
  const BreedDto({
    required this.breedId,
    required this.speciesId,
    required this.name,
  });
  factory BreedDto.fromJson(Map<String, dynamic> json) => BreedDto(
    breedId: (json['breedId'] as num).toInt(),
    speciesId: (json['speciesId'] as num).toInt(),
    name: json['name'] as String,
  );
  final int breedId;
  final int speciesId;
  final String name;
  Breed toDomain() => Breed(breedId: breedId, speciesId: speciesId, name: name);
}

class PetPhotoDto {
  const PetPhotoDto({
    required this.photoId,
    required this.petId,
    required this.url,
    required this.isMain,
    required this.createdAt,
  });
  factory PetPhotoDto.fromJson(Map<String, dynamic> json) => PetPhotoDto(
    photoId: json['photoId'] as String,
    petId: json['petId'] as String,
    url: json['url'] as String,
    isMain: json['isPrimary'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
  final String photoId;
  final String petId;
  final String url;
  final bool isMain;
  final DateTime createdAt;
  PetPhoto toDomain() => PetPhoto(
    photoId: photoId,
    petId: petId,
    url: url,
    isMain: isMain,
    createdAt: createdAt,
  );
}

class CreatePetRequestDto {
  const CreatePetRequestDto(this.draft);
  final PetDraft draft;
  Map<String, dynamic> toJson() => {
    'breedId': draft.breedId,
    'name': draft.name,
    'birthDate': draft.birthDate?.toUtc().toIso8601String(),
    'gender': draft.gender,
    'weight': draft.weight,
    'color': draft.color,
    'pedigreeNumber': draft.pedigreeNumber,
    'isSterilized': draft.isSterilized,
    'description': draft.description,
  };
}

class UpdatePetRequestDto {
  const UpdatePetRequestDto(this.draft);
  final PetDraft draft;
  Map<String, dynamic> toJson() => {
    'name': draft.name,
    'birthDate': draft.birthDate?.toUtc().toIso8601String(),
    'gender': draft.gender,
    'weight': draft.weight,
    'color': draft.color,
    'pedigreeNumber': draft.pedigreeNumber,
    'isSterilized': draft.isSterilized,
    'description': draft.description,
  };
}

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.parse(value as String);
