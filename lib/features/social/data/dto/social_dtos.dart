import '../../domain/entities/social.dart';

class SocialUserDto {
  const SocialUserDto(this.value);
  factory SocialUserDto.fromJson(Map<String, dynamic> json) => SocialUserDto(
    SocialUser(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      socialStatus: json['socialStatus'] == null
          ? null
          : SocialStatus.fromWire(json['socialStatus'] as String),
    ),
  );
  final SocialUser value;
  SocialUser toDomain() => value;
}

class FriendRequestDto {
  const FriendRequestDto(this.value);
  factory FriendRequestDto.fromJson(Map<String, dynamic> json) =>
      FriendRequestDto(
        FriendRequest(
          id: json['id'] as String,
          requesterUserId: json['requesterUserId'] as String,
          addresseeUserId: json['addresseeUserId'] as String,
          status: FriendRequestStatus.fromWire(json['status'] as String),
          createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
          respondedAtUtc: _date(json['respondedAtUtc']),
          user: _user(json['user']),
        ),
      );
  final FriendRequest value;
  FriendRequest toDomain() => value;
}

class FriendshipDto {
  const FriendshipDto(this.value);
  factory FriendshipDto.fromJson(Map<String, dynamic> json) => FriendshipDto(
    Friendship(
      friendshipId: json['friendshipId'] as String,
      user: SocialUserDto.fromJson(
        json['user'] as Map<String, dynamic>,
      ).toDomain(),
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    ),
  );
  final Friendship value;
  Friendship toDomain() => value;
}

class BlockedUserDto {
  const BlockedUserDto(this.value);
  factory BlockedUserDto.fromJson(Map<String, dynamic> json) => BlockedUserDto(
    BlockedUser(
      blockId: json['blockId'] as String,
      user: SocialUserDto.fromJson(
        json['user'] as Map<String, dynamic>,
      ).toDomain(),
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    ),
  );
  final BlockedUser value;
  BlockedUser toDomain() => value;
}

class ChatMessageDto {
  const ChatMessageDto(this.value);
  factory ChatMessageDto.fromJson(Map<String, dynamic> json) => ChatMessageDto(
    ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderUserId: json['senderUserId'] as String,
      content: json['content'] as String,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      editedAtUtc: _date(json['editedAtUtc']),
      deletedAtUtc: _date(json['deletedAtUtc']),
    ),
  );
  final ChatMessage value;
  ChatMessage toDomain() => value;
}

class ConversationDto {
  const ConversationDto(this.value);
  factory ConversationDto.fromJson(Map<String, dynamic> json) =>
      ConversationDto(
        Conversation(
          id: json['id'] as String,
          counterpart: SocialUserDto.fromJson(
            json['counterpart'] as Map<String, dynamic>,
          ).toDomain(),
          lastMessage: json['lastMessage'] is Map<String, dynamic>
              ? ChatMessageDto.fromJson(
                  json['lastMessage'] as Map<String, dynamic>,
                ).toDomain()
              : null,
          createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
          lastMessageAtUtc: _date(json['lastMessageAtUtc']),
          unreadCount: json['unreadCount'] as int,
        ),
      );
  final Conversation value;
  Conversation toDomain() => value;
}

NumberedPage<T> numberedPage<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) parse,
) => NumberedPage<T>(
  items: (json['items'] as List<dynamic>)
      .map((item) => parse(item as Map<String, dynamic>))
      .toList(growable: false),
  pageNumber: json['pageNumber'] as int,
  pageSize: json['pageSize'] as int,
  totalItems: json['totalItems'] as int,
  totalPages: json['totalPages'] as int,
  hasNextPage: json['hasNextPage'] as bool,
);

MessagePage messagePage(Map<String, dynamic> json) {
  final rawCursor = json['nextCursor'];
  return MessagePage(
    items: (json['items'] as List<dynamic>)
        .map(
          (item) =>
              ChatMessageDto.fromJson(item as Map<String, dynamic>).toDomain(),
        )
        .toList(growable: false),
    nextCursor: rawCursor is Map<String, dynamic>
        ? MessageCursor(
            before: DateTime.parse(rawCursor['before'] as String),
            beforeId: rawCursor['beforeId'] as String,
          )
        : null,
    hasMore: json['hasMore'] as bool,
  );
}

MessageReadReceipt readReceipt(Map<String, dynamic> json) => MessageReadReceipt(
  conversationId: json['conversationId'] as String,
  readerUserId: json['readerUserId'] as String,
  lastReadMessageId: json['lastReadMessageId'] as String,
  readAtUtc: DateTime.parse(json['readAtUtc'] as String),
);

SocialUser? _user(Object? value) => value is Map<String, dynamic>
    ? SocialUserDto.fromJson(value).toDomain()
    : null;
DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
