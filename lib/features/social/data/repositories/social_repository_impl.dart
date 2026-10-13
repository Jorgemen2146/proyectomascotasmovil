import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/dio_exception_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/social.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_data_source.dart';
import '../dto/social_dtos.dart';

class SocialRepositoryImpl implements SocialRepository {
  const SocialRepositoryImpl(this._remote);
  final SocialRemoteDataSource _remote;

  @override
  Future<Result<List<SocialUser>>> searchUsers(
    String query, {
    int limit = 20,
  }) => _run(
    () async => (await _remote.searchUsers(
      query,
      limit,
    )).map((item) => item.toDomain()).toList(growable: false),
  );
  @override
  Future<Result<NumberedPage<Friendship>>> getFriends(int page, int pageSize) =>
      _run(
        () async => numberedPage(
          await _remote.getFriends(page, pageSize),
          (json) => FriendshipDto.fromJson(json).toDomain(),
        ),
      );
  @override
  Future<Result<NumberedPage<FriendRequest>>> getIncomingRequests(
    int page,
    int pageSize,
  ) => _run(
    () async => numberedPage(
      await _remote.getIncoming(page, pageSize),
      (json) => FriendRequestDto.fromJson(json).toDomain(),
    ),
  );
  @override
  Future<Result<NumberedPage<FriendRequest>>> getOutgoingRequests(
    int page,
    int pageSize,
  ) => _run(
    () async => numberedPage(
      await _remote.getOutgoing(page, pageSize),
      (json) => FriendRequestDto.fromJson(json).toDomain(),
    ),
  );
  @override
  Future<Result<FriendRequest>> sendFriendRequest(String userId) =>
      _run(() async => (await _remote.sendFriendRequest(userId)).toDomain());
  @override
  Future<Result<FriendRequest>> acceptFriendRequest(String requestId) => _run(
    () async => (await _remote.requestAction(requestId, 'accept')).toDomain(),
  );
  @override
  Future<Result<FriendRequest>> rejectFriendRequest(String requestId) => _run(
    () async => (await _remote.requestAction(requestId, 'reject')).toDomain(),
  );
  @override
  Future<Result<void>> cancelFriendRequest(String requestId) =>
      _run(() => _remote.cancelFriendRequest(requestId));
  @override
  Future<Result<NumberedPage<BlockedUser>>> getBlockedUsers(
    int page,
    int pageSize,
  ) => _run(
    () async => numberedPage(
      await _remote.getBlocked(page, pageSize),
      (json) => BlockedUserDto.fromJson(json).toDomain(),
    ),
  );
  @override
  Future<Result<void>> blockUser(String userId) =>
      _run(() => _remote.blockUser(userId));
  @override
  Future<Result<void>> unblockUser(String userId) =>
      _run(() => _remote.unblockUser(userId));
  @override
  Future<Result<NumberedPage<Conversation>>> getConversations(
    int page,
    int pageSize,
  ) => _run(
    () async => numberedPage(
      await _remote.getConversations(page, pageSize),
      (json) => ConversationDto.fromJson(json).toDomain(),
    ),
  );
  @override
  Future<Result<Conversation>> createConversation(String userId) =>
      _run(() async => (await _remote.createConversation(userId)).toDomain());
  @override
  Future<Result<Conversation>> getConversation(String conversationId) => _run(
    () async => (await _remote.getConversation(conversationId)).toDomain(),
  );
  @override
  Future<Result<MessagePage>> getMessages(
    String conversationId, {
    required int pageSize,
    MessageCursor? cursor,
  }) => _run(
    () async => messagePage(
      await _remote.getMessages(
        conversationId,
        pageSize: pageSize,
        before: cursor?.before,
        beforeId: cursor?.beforeId,
      ),
    ),
  );
  @override
  Future<Result<ChatMessage>> sendMessage(
    String conversationId,
    String content,
  ) => _run(
    () async => (await _remote.sendMessage(conversationId, content)).toDomain(),
  );
  @override
  Future<Result<void>> markConversationRead(String conversationId) =>
      _run(() => _remote.markRead(conversationId));

  Future<Result<T>> _run<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } on DioException catch (error) {
      return Result.failure(_socialFailure(error));
    } catch (_) {
      return const Result.failure(
        UnknownFailure('No pudimos completar la acción.'),
      );
    }
  }
}

AppFailure _socialFailure(DioException error) {
  final data = error.response?.data;
  final code = data is Map ? data['code']?.toString() : null;
  final message = switch (code) {
    'Social.Blocked' =>
      'Esta acción no está disponible porque uno de los usuarios bloqueó al otro.',
    'Social.NotFriends' =>
      'Deben ser amigos para iniciar o continuar esta conversación.',
    'Social.AlreadyFriends' => 'Ya son amigos.',
    'Social.DuplicateRequest' =>
      'Ya existe una solicitud de amistad pendiente.',
    'Social.NotFound' => 'El usuario o recurso ya no está disponible.',
    'Social.Unauthorized' => 'No tienes permiso para realizar esta acción.',
    'Social.SelfRequest' => 'No puedes enviarte una solicitud a ti mismo.',
    'Social.InvalidMessage' => 'El mensaje no es válido.',
    'Social.InvalidPagination' => 'No se pudo cargar esta página.',
    _ => null,
  };
  if (message != null) {
    return ServerFailure(
      message,
      statusCode: error.response?.statusCode,
      errorCode: code,
    );
  }
  return mapExceptionToFailure(mapDioExceptionToAppException(error));
}
