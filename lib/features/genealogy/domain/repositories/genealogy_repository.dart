import '../../../../core/result/result.dart';
import '../entities/genealogy.dart';

abstract class GenealogyRepository {
  Future<Result<GenealogyTree>> getTree({
    required String petId,
    required int generations,
  });
  Future<Result<GenealogyRelationship>> addOwnParent({
    required String childPetId,
    required String parentPetId,
    required GenealogyParentRole role,
  });
  Future<Result<void>> deleteRelationship(String relationshipId);
  Future<Result<GenealogyInvitationCreated>> createInvitation({
    required String childPetId,
    required GenealogyParentRole role,
    required String ownerEmail,
  });
  Future<Result<GenealogyInvitationContext>> getInvitation(String token);
  Future<Result<List<GenealogyInvitation>>> getInvitations({
    required String direction,
    String? status,
  });
  Future<Result<GenealogyRelationship>> acceptInvitation({
    required String token,
    required String petId,
  });
  Future<Result<void>> rejectInvitation(String token);
  Future<Result<void>> cancelInvitation(String invitationId);
}
