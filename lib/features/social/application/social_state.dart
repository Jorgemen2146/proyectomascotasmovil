import '../../../core/errors/app_failure.dart';
import '../domain/entities/social.dart';

class ConversationMessagesState {
  const ConversationMessagesState({
    this.conversation,
    this.messages = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.canSend = true,
    this.failure,
  });
  final Conversation? conversation;
  final List<ChatMessage> messages;
  final MessageCursor? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;
  final bool canSend;
  final AppFailure? failure;

  ConversationMessagesState copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    MessageCursor? nextCursor,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    bool? canSend,
    AppFailure? failure,
    bool clearFailure = false,
  }) => ConversationMessagesState(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    nextCursor: nextCursor ?? this.nextCursor,
    hasMore: hasMore ?? this.hasMore,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isSending: isSending ?? this.isSending,
    canSend: canSend ?? this.canSend,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class SocialState {
  const SocialState({
    this.searchResults = const [],
    this.searchQuery = '',
    this.searchLoading = false,
    this.searchFailure,
    this.friends = const [],
    this.friendsPage = 0,
    this.friendsHasMore = false,
    this.friendsLoading = false,
    this.friendsFailure,
    this.incoming = const [],
    this.incomingPage = 0,
    this.incomingHasMore = false,
    this.outgoing = const [],
    this.outgoingPage = 0,
    this.outgoingHasMore = false,
    this.requestsLoading = false,
    this.requestsFailure,
    this.blocked = const [],
    this.blockedPage = 0,
    this.blockedHasMore = false,
    this.blockedLoading = false,
    this.blockedFailure,
    this.conversations = const [],
    this.unreadMessages = 0,
    this.inboxPage = 0,
    this.inboxHasMore = false,
    this.inboxLoading = false,
    this.inboxFailure,
    this.chats = const {},
    this.busyIds = const {},
    this.activeConversationId,
  });

  final List<SocialUser> searchResults;
  final String searchQuery;
  final bool searchLoading;
  final AppFailure? searchFailure;
  final List<Friendship> friends;
  final int friendsPage;
  final bool friendsHasMore;
  final bool friendsLoading;
  final AppFailure? friendsFailure;
  final List<FriendRequest> incoming;
  final int incomingPage;
  final bool incomingHasMore;
  final List<FriendRequest> outgoing;
  final int outgoingPage;
  final bool outgoingHasMore;
  final bool requestsLoading;
  final AppFailure? requestsFailure;
  final List<BlockedUser> blocked;
  final int blockedPage;
  final bool blockedHasMore;
  final bool blockedLoading;
  final AppFailure? blockedFailure;
  final List<Conversation> conversations;
  final int unreadMessages;
  final int inboxPage;
  final bool inboxHasMore;
  final bool inboxLoading;
  final AppFailure? inboxFailure;
  final Map<String, ConversationMessagesState> chats;
  final Set<String> busyIds;
  final String? activeConversationId;

  int get pendingRequests => incoming.length;

  SocialState copyWith({
    List<SocialUser>? searchResults,
    String? searchQuery,
    bool? searchLoading,
    AppFailure? searchFailure,
    List<Friendship>? friends,
    int? friendsPage,
    bool? friendsHasMore,
    bool? friendsLoading,
    AppFailure? friendsFailure,
    List<FriendRequest>? incoming,
    int? incomingPage,
    bool? incomingHasMore,
    List<FriendRequest>? outgoing,
    int? outgoingPage,
    bool? outgoingHasMore,
    bool? requestsLoading,
    AppFailure? requestsFailure,
    List<BlockedUser>? blocked,
    int? blockedPage,
    bool? blockedHasMore,
    bool? blockedLoading,
    AppFailure? blockedFailure,
    List<Conversation>? conversations,
    int? unreadMessages,
    int? inboxPage,
    bool? inboxHasMore,
    bool? inboxLoading,
    AppFailure? inboxFailure,
    Map<String, ConversationMessagesState>? chats,
    Set<String>? busyIds,
    String? activeConversationId,
    bool clearActiveConversation = false,
  }) => SocialState(
    searchResults: searchResults ?? this.searchResults,
    searchQuery: searchQuery ?? this.searchQuery,
    searchLoading: searchLoading ?? this.searchLoading,
    searchFailure: searchFailure,
    friends: friends ?? this.friends,
    friendsPage: friendsPage ?? this.friendsPage,
    friendsHasMore: friendsHasMore ?? this.friendsHasMore,
    friendsLoading: friendsLoading ?? this.friendsLoading,
    friendsFailure: friendsFailure,
    incoming: incoming ?? this.incoming,
    incomingPage: incomingPage ?? this.incomingPage,
    incomingHasMore: incomingHasMore ?? this.incomingHasMore,
    outgoing: outgoing ?? this.outgoing,
    outgoingPage: outgoingPage ?? this.outgoingPage,
    outgoingHasMore: outgoingHasMore ?? this.outgoingHasMore,
    requestsLoading: requestsLoading ?? this.requestsLoading,
    requestsFailure: requestsFailure,
    blocked: blocked ?? this.blocked,
    blockedPage: blockedPage ?? this.blockedPage,
    blockedHasMore: blockedHasMore ?? this.blockedHasMore,
    blockedLoading: blockedLoading ?? this.blockedLoading,
    blockedFailure: blockedFailure,
    conversations: conversations ?? this.conversations,
    unreadMessages: unreadMessages ?? this.unreadMessages,
    inboxPage: inboxPage ?? this.inboxPage,
    inboxHasMore: inboxHasMore ?? this.inboxHasMore,
    inboxLoading: inboxLoading ?? this.inboxLoading,
    inboxFailure: inboxFailure,
    chats: chats ?? this.chats,
    busyIds: busyIds ?? this.busyIds,
    activeConversationId: clearActiveConversation
        ? null
        : activeConversationId ?? this.activeConversationId,
  );
}
