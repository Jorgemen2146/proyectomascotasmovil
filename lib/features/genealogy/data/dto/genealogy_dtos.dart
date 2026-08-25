import '../../domain/entities/genealogy.dart';

class GenealogyPetNodeDto {
  const GenealogyPetNodeDto({
    required this.petId,
    required this.name,
    required this.sex,
    required this.speciesId,
    this.breedName,
    this.mainPhotoUrl,
    this.birthDate,
  });
  factory GenealogyPetNodeDto.fromJson(Map<String, dynamic> json) =>
      GenealogyPetNodeDto(
        petId: json['petId'] as String,
        name: json['name'] as String,
        sex: json['sex'] as String,
        speciesId: json['speciesId'] as int,
        breedName: json['breedName'] as String?,
        mainPhotoUrl: json['mainPhotoUrl'] as String?,
        birthDate: _date(json['birthDate']),
      );
  final String petId;
  final String name;
  final String sex;
  final int speciesId;
  final String? breedName;
  final String? mainPhotoUrl;
  final DateTime? birthDate;
  GenealogyPetNode toDomain() => GenealogyPetNode(
    petId: petId,
    name: name,
    sex: sex,
    speciesId: speciesId,
    breedName: breedName,
    mainPhotoUrl: mainPhotoUrl,
    birthDate: birthDate,
  );
}

class GenealogyParentNodeDto {
  const GenealogyParentNodeDto({
    required this.relationshipId,
    required this.role,
    required this.pet,
    required this.parents,
  });
  factory GenealogyParentNodeDto.fromJson(Map<String, dynamic> json) =>
      GenealogyParentNodeDto(
        relationshipId: json['relationshipId'] as String,
        role: json['role'] as String,
        pet: GenealogyPetNodeDto.fromJson(json['pet'] as Map<String, dynamic>),
        parents: (json['parents'] as List<dynamic>? ?? const [])
            .map(
              (e) => GenealogyParentNodeDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
  final String relationshipId;
  final String role;
  final GenealogyPetNodeDto pet;
  final List<GenealogyParentNodeDto> parents;
  GenealogyParentNode toDomain() => GenealogyParentNode(
    relationshipId: relationshipId,
    role: role,
    pet: pet.toDomain(),
    parents: parents.map((e) => e.toDomain()).toList(growable: false),
  );
}

class GenealogyChildNodeDto {
  const GenealogyChildNodeDto({
    required this.relationshipId,
    required this.pet,
  });
  factory GenealogyChildNodeDto.fromJson(Map<String, dynamic> json) =>
      GenealogyChildNodeDto(
        relationshipId: json['relationshipId'] as String,
        pet: GenealogyPetNodeDto.fromJson(json['pet'] as Map<String, dynamic>),
      );
  final String relationshipId;
  final GenealogyPetNodeDto pet;
  GenealogyChildNode toDomain() =>
      GenealogyChildNode(relationshipId: relationshipId, pet: pet.toDomain());
}

class GenealogyTreeDto {
  const GenealogyTreeDto({
    required this.pet,
    required this.parents,
    required this.children,
  });
  factory GenealogyTreeDto.fromJson(
    Map<String, dynamic> json,
  ) => GenealogyTreeDto(
    pet: GenealogyPetNodeDto.fromJson(json['pet'] as Map<String, dynamic>),
    parents: (json['parents'] as List<dynamic>? ?? const [])
        .map((e) => GenealogyParentNodeDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    children: (json['children'] as List<dynamic>? ?? const [])
        .map((e) => GenealogyChildNodeDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
  final GenealogyPetNodeDto pet;
  final List<GenealogyParentNodeDto> parents;
  final List<GenealogyChildNodeDto> children;
  GenealogyTree toDomain() => GenealogyTree(
    pet: pet.toDomain(),
    parents: parents.map((e) => e.toDomain()).toList(growable: false),
    children: children.map((e) => e.toDomain()).toList(growable: false),
  );
}

class RelationshipCreatedDto {
  const RelationshipCreatedDto(this.relationshipId, this.status);
  factory RelationshipCreatedDto.fromJson(Map<String, dynamic> json) =>
      RelationshipCreatedDto(
        json['relationshipId'] as String,
        json['status'] as String,
      );
  final String relationshipId;
  final String status;
  GenealogyRelationship toDomain() =>
      GenealogyRelationship(relationshipId: relationshipId, status: status);
}

class InvitationCreatedDto {
  const InvitationCreatedDto(
    this.invitationId,
    this.status,
    this.expiresAtUtc,
    this.invitationToken,
  );
  factory InvitationCreatedDto.fromJson(Map<String, dynamic> json) =>
      InvitationCreatedDto(
        json['invitationId'] as String,
        json['status'] as String,
        DateTime.parse(json['expiresAtUtc'] as String),
        json['invitationToken'] as String,
      );
  final String invitationId;
  final String status;
  final DateTime expiresAtUtc;
  final String invitationToken;
  GenealogyInvitationCreated toDomain() => GenealogyInvitationCreated(
    invitationId: invitationId,
    status: status,
    expiresAtUtc: expiresAtUtc,
    invitationToken: invitationToken,
  );
}

class InvitationListItemDto {
  const InvitationListItemDto(
    this.invitationId,
    this.childPetId,
    this.childPetName,
    this.parentRole,
    this.direction,
    this.status,
    this.expiresAtUtc,
    this.createdAtUtc,
  );
  factory InvitationListItemDto.fromJson(Map<String, dynamic> json) =>
      InvitationListItemDto(
        json['invitationId'] as String,
        json['childPetId'] as String,
        json['childPetName'] as String,
        json['parentRole'] as String,
        json['direction'] as String,
        json['status'] as String,
        DateTime.parse(json['expiresAtUtc'] as String),
        DateTime.parse(json['createdAtUtc'] as String),
      );
  final String invitationId,
      childPetId,
      childPetName,
      parentRole,
      direction,
      status;
  final DateTime expiresAtUtc, createdAtUtc;
  GenealogyInvitation toDomain() => GenealogyInvitation(
    invitationId: invitationId,
    childPetId: childPetId,
    childPetName: childPetName,
    parentRole: parentRole,
    direction: direction,
    status: status,
    expiresAtUtc: expiresAtUtc,
    createdAtUtc: createdAtUtc,
  );
}

class InvitationContextDto {
  const InvitationContextDto(
    this.invitationId,
    this.requesterDisplayName,
    this.childPetId,
    this.childPetName,
    this.childMainPhotoUrl,
    this.parentRole,
    this.expiresAtUtc,
    this.status,
  );
  factory InvitationContextDto.fromJson(Map<String, dynamic> json) =>
      InvitationContextDto(
        json['invitationId'] as String,
        json['requesterDisplayName'] as String,
        json['childPetId'] as String,
        json['childPetName'] as String,
        json['childMainPhotoUrl'] as String?,
        json['parentRole'] as String,
        DateTime.parse(json['expiresAtUtc'] as String),
        json['status'] as String,
      );
  final String invitationId,
      requesterDisplayName,
      childPetId,
      childPetName,
      parentRole,
      status;
  final String? childMainPhotoUrl;
  final DateTime expiresAtUtc;
  GenealogyInvitationContext toDomain() => GenealogyInvitationContext(
    invitationId: invitationId,
    requesterDisplayName: requesterDisplayName,
    childPetId: childPetId,
    childPetName: childPetName,
    childMainPhotoUrl: childMainPhotoUrl,
    parentRole: parentRole,
    expiresAtUtc: expiresAtUtc,
    status: status,
  );
}

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.parse(value as String);
