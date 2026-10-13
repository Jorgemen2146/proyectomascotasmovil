enum SocialStatus {
  none,
  friends,
  pendingSent,
  pendingReceived;

  static SocialStatus fromWire(String value) => switch (value) {
    'None' => SocialStatus.none,
    'Friends' => SocialStatus.friends,
    'PendingSent' => SocialStatus.pendingSent,
    'PendingReceived' => SocialStatus.pendingReceived,
    _ => throw FormatException('Unknown SocialStatus: $value'),
  };
}

enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled;

  static FriendRequestStatus fromWire(String value) => switch (value) {
    'Pending' => FriendRequestStatus.pending,
    'Accepted' => FriendRequestStatus.accepted,
    'Rejected' => FriendRequestStatus.rejected,
    'Cancelled' => FriendRequestStatus.cancelled,
    _ => throw FormatException('Unknown FriendRequestStatus: $value'),
  };
}

class SocialUser {
  const SocialUser({
    required this.userId,
    required this.displayName,
    this.profilePhotoUrl,
    this.socialStatus,
  });

  final String userId;
  final String displayName;
  final String? profilePhotoUrl;
  final SocialStatus? socialStatus;

  SocialUser copyWith({SocialStatus? socialStatus}) => SocialUser(
    userId: userId,
    displayName: displayName,
    profilePhotoUrl: profilePhotoUrl,
    socialStatus: socialStatus ?? this.socialStatus,
  );
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.requesterUserId,
    required this.addresseeUserId,
    required this.status,
    required this.createdAtUtc,
    this.respondedAtUtc,
    this.user,
  });

  final String id;
  final String requesterUserId;
  final String addresseeUserId;
  final FriendRequestStatus status;
  final DateTime createdAtUtc;
  final DateTime? respondedAtUtc;
  final SocialUser? user;
}

class Friendship {
  const Friendship({
    required this.friendshipId,
    required this.user,
    required this.createdAtUtc,
  });
  final String friendshipId;
  final SocialUser user;
  final DateTime createdAtUtc;
}

class BlockedUser {
  const BlockedUser({
    required this.blockId,
    required this.user,
    required this.createdAtUtc,
  });
  final String blockId;
  final SocialUser user;
  final DateTime createdAtUtc;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.content,
    required this.createdAtUtc,
    this.editedAtUtc,
    this.deletedAtUtc,
  });
  final String id;
  final String conversationId;
  final String senderUserId;
  final String content;
  final DateTime createdAtUtc;
  final DateTime? editedAtUtc;
  final DateTime? deletedAtUtc;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.counterpart,
    required this.createdAtUtc,
    required this.unreadCount,
    this.lastMessage,
    this.lastMessageAtUtc,
  });
  final String id;
  final SocialUser counterpart;
  final ChatMessage? lastMessage;
  final DateTime createdAtUtc;
  final DateTime? lastMessageAtUtc;
  final int unreadCount;

  Conversation copyWith({
    ChatMessage? lastMessage,
    DateTime? lastMessageAtUtc,
    int? unreadCount,
  }) => Conversation(
    id: id,
    counterpart: counterpart,
    lastMessage: lastMessage ?? this.lastMessage,
    createdAtUtc: createdAtUtc,
    lastMessageAtUtc: lastMessageAtUtc ?? this.lastMessageAtUtc,
    unreadCount: unreadCount ?? this.unreadCount,
  );
}

class NumberedPage<T> {
  const NumberedPage({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
  });
  final List<T> items;
  final int pageNumber;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
}

class MessageCursor {
  const MessageCursor({required this.before, required this.beforeId});
  final DateTime before;
  final String beforeId;
}

class MessagePage {
  const MessagePage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
  final List<ChatMessage> items;
  final MessageCursor? nextCursor;
  final bool hasMore;
}

class MessageReadReceipt {
  const MessageReadReceipt({
    required this.conversationId,
    required this.readerUserId,
    required this.lastReadMessageId,
    required this.readAtUtc,
  });
  final String conversationId;
  final String readerUserId;
  final String lastReadMessageId;
  final DateTime readAtUtc;
}
