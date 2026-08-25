import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/genealogy/domain/entities/genealogy.dart';
import 'package:dogplatform/features/genealogy/domain/repositories/genealogy_repository.dart';
import 'package:dogplatform/features/pets/domain/entities/pet.dart';

class FakeGenealogyRepository implements GenealogyRepository {
  GenealogyTree tree = sampleTree;
  List<GenealogyInvitation> invitations = const [];
  int getTreeCalls = 0;
  String? addedChildId;
  String? addedParentId;
  GenealogyParentRole? addedRole;
  String? deletedRelationshipId;
  String? invitedEmail;
  String? acceptedToken;
  String? acceptedPetId;
  String? rejectedToken;
  String? cancelledInvitationId;

  @override
  Future<Result<GenealogyTree>> getTree({
    required String petId,
    required int generations,
  }) async {
    getTreeCalls++;
    return Result.success(tree);
  }

  @override
  Future<Result<GenealogyRelationship>> addOwnParent({
    required String childPetId,
    required String parentPetId,
    required GenealogyParentRole role,
  }) async {
    addedChildId = childPetId;
    addedParentId = parentPetId;
    addedRole = role;
    return const Result.success(
      GenealogyRelationship(
        relationshipId: 'relationship-new',
        status: 'Active',
      ),
    );
  }

  @override
  Future<Result<void>> deleteRelationship(String relationshipId) async {
    deletedRelationshipId = relationshipId;
    return const Result.success(null);
  }

  @override
  Future<Result<GenealogyInvitationCreated>> createInvitation({
    required String childPetId,
    required GenealogyParentRole role,
    required String ownerEmail,
  }) async {
    invitedEmail = ownerEmail;
    return Result.success(
      GenealogyInvitationCreated(
        invitationId: 'invitation-new',
        status: 'Pending',
        expiresAtUtc: DateTime.utc(2026, 9),
        invitationToken: 'token-new',
      ),
    );
  }

  @override
  Future<Result<GenealogyInvitationContext>> getInvitation(
    String token,
  ) async => Result.success(
    GenealogyInvitationContext(
      invitationId: 'invitation-1',
      requesterDisplayName: 'Jorge',
      childPetId: 'root',
      childPetName: 'Andrea Kitty',
      parentRole: 'Father',
      expiresAtUtc: DateTime.utc(2026, 9),
      status: 'Pending',
    ),
  );

  @override
  Future<Result<List<GenealogyInvitation>>> getInvitations({
    required String direction,
    String? status,
  }) async => Result.success(
    invitations.where((item) => item.direction == direction).toList(),
  );

  @override
  Future<Result<GenealogyRelationship>> acceptInvitation({
    required String token,
    required String petId,
  }) async {
    acceptedToken = token;
    acceptedPetId = petId;
    return const Result.success(
      GenealogyRelationship(
        relationshipId: 'relationship-accepted',
        status: 'Active',
      ),
    );
  }

  @override
  Future<Result<void>> rejectInvitation(String token) async {
    rejectedToken = token;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> cancelInvitation(String invitationId) async {
    cancelledInvitationId = invitationId;
    return const Result.success(null);
  }
}

final samplePets = [
  PetSummary(
    id: 'root',
    name: 'Andrea Kitty',
    speciesId: 1,
    speciesName: 'Gato',
    breedId: 1,
    breedName: 'Bombay',
    sex: 'F',
    createdAt: DateTime.utc(2026),
  ),
  PetSummary(
    id: 'father',
    name: 'Tom',
    speciesId: 1,
    speciesName: 'Gato',
    breedId: 1,
    breedName: 'Bombay',
    sex: 'M',
    createdAt: DateTime.utc(2025),
  ),
  PetSummary(
    id: 'mother',
    name: 'Mia',
    speciesId: 1,
    speciesName: 'Gato',
    breedId: 1,
    breedName: 'Bombay',
    sex: 'F',
    createdAt: DateTime.utc(2025),
  ),
];

const rootPet = GenealogyPetNode(
  petId: 'root',
  name: 'Andrea Kitty',
  sex: 'F',
  speciesId: 1,
  breedName: 'Bombay',
);

const sampleTree = GenealogyTree(
  pet: rootPet,
  parents: [
    GenealogyParentNode(
      relationshipId: 'rel-father',
      role: 'Father',
      pet: GenealogyPetNode(
        petId: 'father',
        name: 'Tom',
        sex: 'M',
        speciesId: 1,
        breedName: 'Bombay',
      ),
      parents: [],
    ),
    GenealogyParentNode(
      relationshipId: 'rel-mother',
      role: 'Mother',
      pet: GenealogyPetNode(
        petId: 'mother',
        name: 'Mia',
        sex: 'F',
        speciesId: 1,
        breedName: 'Bombay',
      ),
      parents: [],
    ),
  ],
  children: [
    GenealogyChildNode(
      relationshipId: 'rel-child',
      pet: GenealogyPetNode(
        petId: 'child',
        name: 'Nina',
        sex: 'F',
        speciesId: 1,
      ),
    ),
  ],
);

const emptyTree = GenealogyTree(pet: rootPet, parents: [], children: []);

final pendingInvitation = GenealogyInvitation(
  invitationId: 'invitation-1',
  childPetId: 'root',
  childPetName: 'Andrea Kitty',
  parentRole: 'Father',
  direction: 'outgoing',
  status: 'Pending',
  expiresAtUtc: DateTime.utc(2026, 9),
  createdAtUtc: DateTime.utc(2026, 8),
);

final incomingInvitation = GenealogyInvitation(
  invitationId: 'invitation-incoming',
  childPetId: 'root',
  childPetName: 'Andrea Kitty',
  parentRole: 'Mother',
  direction: 'incoming',
  status: 'Pending',
  expiresAtUtc: DateTime.utc(2026, 9),
  createdAtUtc: DateTime.utc(2026, 8),
);
