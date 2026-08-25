import 'package:dio/dio.dart';
import '../../../../core/constants/api_paths.dart';
import '../../domain/entities/genealogy.dart';
import '../dto/genealogy_dtos.dart';

class GenealogyRemoteDataSource {
  const GenealogyRemoteDataSource({required Dio dio}) : this._internal(dio);
  const GenealogyRemoteDataSource._internal(this._dio);
  final Dio _dio;

  Future<GenealogyTreeDto> getTree(String petId, int generations) async =>
      GenealogyTreeDto.fromJson(
        (await _dio.get<Map<String, dynamic>>(
          ApiPaths.genealogyTree(petId),
          queryParameters: {'generations': generations},
        )).data!,
      );
  Future<RelationshipCreatedDto> addOwnParent(
    String childPetId,
    String parentPetId,
    GenealogyParentRole role,
  ) async => RelationshipCreatedDto.fromJson(
    (await _dio.post<Map<String, dynamic>>(
      ApiPaths.genealogyParents(childPetId),
      data: {'parentPetId': parentPetId, 'parentRole': role.apiValue},
    )).data!,
  );
  Future<void> deleteRelationship(String id) =>
      _dio.delete<void>(ApiPaths.genealogyRelationship(id));
  Future<InvitationCreatedDto> createInvitation(
    String childPetId,
    GenealogyParentRole role,
    String ownerEmail,
  ) async => InvitationCreatedDto.fromJson(
    (await _dio.post<Map<String, dynamic>>(
      ApiPaths.genealogyInvitations,
      data: {
        'childPetId': childPetId,
        'parentRole': role.apiValue,
        'ownerEmail': ownerEmail,
      },
    )).data!,
  );
  Future<InvitationContextDto> getInvitation(String token) async =>
      InvitationContextDto.fromJson(
        (await _dio.get<Map<String, dynamic>>(
          ApiPaths.genealogyInvitation(token),
        )).data!,
      );
  Future<List<InvitationListItemDto>> getInvitations(
    String direction,
    String? status,
  ) async =>
      ((await _dio.get<List<dynamic>>(
                ApiPaths.genealogyMyInvitations,
                queryParameters: {'direction': direction, 'status': ?status},
              )).data ??
              const [])
          .map((e) => InvitationListItemDto.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
  Future<RelationshipCreatedDto> acceptInvitation(
    String token,
    String petId,
  ) async => RelationshipCreatedDto.fromJson(
    (await _dio.post<Map<String, dynamic>>(
      ApiPaths.genealogyAcceptInvitation(token),
      data: {'petId': petId},
    )).data!,
  );
  Future<void> rejectInvitation(String token) =>
      _dio.post<void>(ApiPaths.genealogyRejectInvitation(token));
  Future<void> cancelInvitation(String id) =>
      _dio.post<void>(ApiPaths.genealogyCancelInvitation(id));
}
