import '../../../../core/result/result.dart';
import '../entities/social.dart';

abstract class SocialRepository {
  Future<Result<List<SocialUser>>> searchUsers(String query, {int limit = 20});
  Future<Result<NumberedPage<Friendship>>> getFriends(int page, int pageSize);
  Future<Result<NumberedPage<FriendRequest>>> getIncomingRequests(
    int page,
    int pageSize,
  );
  Future<Result<NumberedPage<FriendRequest>>> getOutgoingRequests(
    int page,
    int pageSize,
  );
  Future<Result<FriendRequest>> sendFriendRequest(String userId);
  Future<Result<FriendRequest>> acceptFriendRequest(String requestId);
  Future<Result<FriendRequest>> rejectFriendRequest(String requestId);
  Future<Result<void>> cancelFriendRequest(String requestId);
  Future<Result<NumberedPage<BlockedUser>>> getBlockedUsers(
    int page,
    int pageSize,
  );
  Future<Result<void>> blockUser(String userId);
  Future<Result<void>> unblockUser(String userId);
  Future<Result<NumberedPage<Conversation>>> getConversations(
    int page,
    int pageSize,
  );
  Future<Result<Conversation>> createConversation(String userId);
  Future<Result<Conversation>> getConversation(String conversationId);
  Future<Result<MessagePage>> getMessages(
    String conversationId, {
    required int pageSize,
    MessageCursor? cursor,
  });
  Future<Result<ChatMessage>> sendMessage(
    String conversationId,
    String content,
  );
  Future<Result<void>> markConversationRead(String conversationId);
}
