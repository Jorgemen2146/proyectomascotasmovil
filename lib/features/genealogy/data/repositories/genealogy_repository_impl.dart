import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/dio_exception_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/genealogy.dart';
import '../../domain/repositories/genealogy_repository.dart';
import '../datasources/genealogy_remote_data_source.dart';

class GenealogyRepositoryImpl implements GenealogyRepository {
  const GenealogyRepositoryImpl(this._remote);

  final GenealogyRemoteDataSource _remote;

  @override
  Future<Result<GenealogyTree>> getTree({
    required String petId,
    required int generations,
  }) =>
      _run(() async => (await _remote.getTree(petId, generations)).toDomain());

  @override
  Future<Result<GenealogyRelationship>> addOwnParent({
    required String childPetId,
    required String parentPetId,
    required GenealogyParentRole role,
  }) => _run(
    () async =>
        (await _remote.addOwnParent(childPetId, parentPetId, role)).toDomain(),
  );

  @override
  Future<Result<void>> deleteRelationship(String relationshipId) =>
      _run(() => _remote.deleteRelationship(relationshipId));

  @override
  Future<Result<GenealogyInvitationCreated>> createInvitation({
    required String childPetId,
    required GenealogyParentRole role,
    required String ownerEmail,
  }) => _run(
    () async => (await _remote.createInvitation(
      childPetId,
      role,
      ownerEmail,
    )).toDomain(),
  );

  @override
  Future<Result<GenealogyInvitationContext>> getInvitation(String token) =>
      _run(() async => (await _remote.getInvitation(token)).toDomain());

  @override
  Future<Result<List<GenealogyInvitation>>> getInvitations({
    required String direction,
    String? status,
  }) => _run(
    () async => (await _remote.getInvitations(
      direction,
      status,
    )).map((item) => item.toDomain()).toList(growable: false),
  );

  @override
  Future<Result<GenealogyRelationship>> acceptInvitation({
    required String token,
    required String petId,
  }) => _run(
    () async => (await _remote.acceptInvitation(token, petId)).toDomain(),
  );

  @override
  Future<Result<void>> rejectInvitation(String token) =>
      _run(() => _remote.rejectInvitation(token));

  @override
  Future<Result<void>> cancelInvitation(String invitationId) =>
      _run(() => _remote.cancelInvitation(invitationId));

  Future<Result<T>> _run<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } on DioException catch (error) {
      return Result.failure(_mapGenealogyFailure(error));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }
}

AppFailure _mapGenealogyFailure(DioException error) {
  final data = error.response?.data;
  final code = data is Map
      ? (data['code'] ?? data['errorId'] ?? data['error'] ?? '')
            .toString()
            .toUpperCase()
      : '';
  const messages = <String, String>{
    'GENEALOGY_RELATIONSHIP_EXISTS': 'Esta relación ya existe.',
    'GENEALOGY_PARENT_ALREADY_ASSIGNED':
        'Esta mascota ya tiene ese progenitor registrado.',
    'GENEALOGY_CYCLE_DETECTED': 'Esta relación generaría un ciclo en el árbol.',
    'GENEALOGY_SELF_RELATIONSHIP':
        'Una mascota no puede ser su propio progenitor.',
    'GENEALOGY_PARENT_SEX_MISMATCH':
        'El sexo de la mascota no corresponde al progenitor seleccionado.',
    'GENEALOGY_INVITATION_EXPIRED': 'La invitación ha expirado.',
    'GENEALOGY_INVITATION_INVALID': 'La invitación no es válida.',
    'GENEALOGY_INVITATION_ALREADY_PROCESSED': 'La invitación ya fue procesada.',
    'GENEALOGY_FORBIDDEN': 'No tienes permiso para realizar esta acción.',
    'GENEALOGY_INVITATION_ALREADY_PENDING':
        'Ya existe una invitación pendiente equivalente.',
    'GENEALOGY_PARENT_ROLE_INVALID': 'El rol del progenitor no es válido.',
    'GENEALOGY_INVITATION_EMAIL_INVALID': 'Ingresa un correo válido.',
    'GENEALOGY_GENERATIONS_INVALID':
        'La cantidad de generaciones debe estar entre 1 y 5.',
  };
  final message = messages[code];
  if (message != null) {
    return code == 'GENEALOGY_FORBIDDEN'
        ? UnauthorizedFailure(message)
        : ValidationFailure(message);
  }
  return mapExceptionToFailure(mapDioExceptionToAppException(error));
}
