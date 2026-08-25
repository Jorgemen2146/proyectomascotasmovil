enum GenealogyParentRole { father, mother }

extension GenealogyParentRoleContract on GenealogyParentRole {
  String get apiValue =>
      this == GenealogyParentRole.father ? 'Father' : 'Mother';
}

class GenealogyPetNode {
  const GenealogyPetNode({
    required this.petId,
    required this.name,
    required this.sex,
    required this.speciesId,
    this.breedName,
    this.mainPhotoUrl,
    this.birthDate,
  });
  final String petId;
  final String name;
  final String sex;
  final int speciesId;
  final String? breedName;
  final String? mainPhotoUrl;
  final DateTime? birthDate;
}

class GenealogyParentNode {
  const GenealogyParentNode({
    required this.relationshipId,
    required this.role,
    required this.pet,
    required this.parents,
  });
  final String relationshipId;
  final String role;
  final GenealogyPetNode pet;
  final List<GenealogyParentNode> parents;
  GenealogyParentRole? get parentRole => switch (role.toLowerCase()) {
    'father' => GenealogyParentRole.father,
    'mother' => GenealogyParentRole.mother,
    _ => null,
  };
}

class GenealogyChildNode {
  const GenealogyChildNode({required this.relationshipId, required this.pet});
  final String relationshipId;
  final GenealogyPetNode pet;
}

class GenealogyTree {
  const GenealogyTree({
    required this.pet,
    required this.parents,
    required this.children,
  });
  final GenealogyPetNode pet;
  final List<GenealogyParentNode> parents;
  final List<GenealogyChildNode> children;
  String get rootPetId => pet.petId;
  bool get hasRelationships => parents.isNotEmpty || children.isNotEmpty;
  GenealogyParentNode? parentFor(GenealogyParentRole role) {
    for (final parent in parents) {
      if (parent.parentRole == role) return parent;
    }
    return null;
  }
}

class GenealogyRelationship {
  const GenealogyRelationship({
    required this.relationshipId,
    required this.status,
  });
  final String relationshipId;
  final String status;
}

class GenealogyInvitationCreated {
  const GenealogyInvitationCreated({
    required this.invitationId,
    required this.status,
    required this.expiresAtUtc,
    required this.invitationToken,
  });
  final String invitationId;
  final String status;
  final DateTime expiresAtUtc;
  final String invitationToken;
}

class GenealogyInvitation {
  const GenealogyInvitation({
    required this.invitationId,
    required this.childPetId,
    required this.childPetName,
    required this.parentRole,
    required this.direction,
    required this.status,
    required this.expiresAtUtc,
    required this.createdAtUtc,
  });
  final String invitationId;
  final String childPetId;
  final String childPetName;
  final String parentRole;
  final String direction;
  final String status;
  final DateTime expiresAtUtc;
  final DateTime createdAtUtc;
  bool get isPending => status.toLowerCase() == 'pending';
}

class GenealogyInvitationContext {
  const GenealogyInvitationContext({
    required this.invitationId,
    required this.requesterDisplayName,
    required this.childPetId,
    required this.childPetName,
    required this.parentRole,
    required this.expiresAtUtc,
    required this.status,
    this.childMainPhotoUrl,
  });
  final String invitationId;
  final String requesterDisplayName;
  final String childPetId;
  final String childPetName;
  final String? childMainPhotoUrl;
  final String parentRole;
  final DateTime expiresAtUtc;
  final String status;
}
