import 'package:dio/dio.dart';

import '../dto/social_dtos.dart';

class SocialRemoteDataSource {
  const SocialRemoteDataSource(this._dio);
  final Dio _dio;
  static const _base = '/api/v1/social';

  Future<List<SocialUserDto>> searchUsers(String query, int limit) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/users/search',
      queryParameters: {'query': query, 'limit': limit},
    );
    return response.data!
        .map((item) => SocialUserDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getFriends(int page, int pageSize) =>
      _getPage('$_base/friends', page, pageSize);
  Future<Map<String, dynamic>> getIncoming(int page, int pageSize) =>
      _getPage('$_base/friend-requests/incoming', page, pageSize);
  Future<Map<String, dynamic>> getOutgoing(int page, int pageSize) =>
      _getPage('$_base/friend-requests/outgoing', page, pageSize);
  Future<Map<String, dynamic>> getBlocked(int page, int pageSize) =>
      _getPage('$_base/blocked-users', page, pageSize);
  Future<Map<String, dynamic>> getConversations(int page, int pageSize) =>
      _getPage('$_base/conversations', page, pageSize);

  Future<FriendRequestDto> sendFriendRequest(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/friend-requests',
      data: {'addresseeUserId': userId},
    );
    return FriendRequestDto.fromJson(response.data!);
  }

  Future<FriendRequestDto> requestAction(
    String requestId,
    String action,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/friend-requests/$requestId/$action',
    );
    return FriendRequestDto.fromJson(response.data!);
  }

  Future<void> cancelFriendRequest(String requestId) =>
      _dio.delete<void>('$_base/friend-requests/$requestId');
  Future<void> blockUser(String userId) =>
      _dio.post<void>('$_base/users/$userId/block');
  Future<void> unblockUser(String userId) =>
      _dio.delete<void>('$_base/users/$userId/block');

  Future<ConversationDto> createConversation(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/conversations',
      data: {'userId': userId},
    );
    return ConversationDto.fromJson(response.data!);
  }

  Future<ConversationDto> getConversation(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/conversations/$id',
    );
    return ConversationDto.fromJson(response.data!);
  }

  Future<Map<String, dynamic>> getMessages(
    String id, {
    required int pageSize,
    DateTime? before,
    String? beforeId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/conversations/$id/messages',
      queryParameters: {
        'pageSize': pageSize,
        if (before != null) 'before': before.toUtc().toIso8601String(),
        'beforeId': ?beforeId,
      },
    );
    return response.data!;
  }

  Future<ChatMessageDto> sendMessage(String id, String content) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/conversations/$id/messages',
      data: {'content': content},
    );
    return ChatMessageDto.fromJson(response.data!);
  }

  Future<void> markRead(String id) =>
      _dio.post<void>('$_base/conversations/$id/read');

  Future<Map<String, dynamic>> _getPage(
    String path,
    int page,
    int pageSize,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data!;
  }
}
