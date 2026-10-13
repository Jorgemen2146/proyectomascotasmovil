import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/realtime/realtime_client.dart';
import '../../../core/result/result.dart';
import '../../authentication/application/auth_state.dart';
import '../../authentication/application/auth_state_controller.dart';
import '../../notifications/application/providers.dart';
import '../data/datasources/social_remote_data_source.dart';
import '../data/dto/social_dtos.dart';
import '../data/repositories/social_repository_impl.dart';
import '../domain/entities/social.dart';
import '../domain/repositories/social_repository.dart';
import 'social_state.dart';

final socialRemoteDataSourceProvider = Provider<SocialRemoteDataSource>(
  (ref) => SocialRemoteDataSource(ref.read(gatewayDioProvider)),
);
final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepositoryImpl(ref.read(socialRemoteDataSourceProvider)),
);

class SocialController extends Notifier<SocialState> {
  static const pageSize = 20;
  static const messagePageSize = 50;

  SocialRepository get _repository => ref.read(socialRepositoryProvider);
  StreamSubscription<RealtimeEvent>? _eventSubscription;
  StreamSubscription<void>? _connectionSubscription;
  final Set<String> _knownMessageIds = <String>{};
  int _sessionGeneration = 0;

  @override
  SocialState build() {
    ref.onDispose(() async {
      await _eventSubscription?.cancel();
      await _connectionSubscription?.cancel();
    });
    return const SocialState();
  }

  void initializeRealtime() {
    if (_eventSubscription != null) return;
    final realtime = ref.read(realtimeClientProvider);
    _eventSubscription = realtime.events.listen(_handleRealtimeEvent);
    _connectionSubscription = realtime.connections.listen(
      (_) => unawaited(reconcile()),
    );
  }

  Future<void> reconcile() async {
    await Future.wait([loadInbox(force: true), loadRequests(force: true)]);
    final active = state.activeConversationId;
    if (active != null) await loadConversation(active, force: true);
  }

  void clear() {
    _sessionGeneration++;
    _knownMessageIds.clear();
    state = const SocialState();
  }

  Future<void> search(String rawQuery) async {
    final generation = _sessionGeneration;
    final query = rawQuery.trim();
    if (query.isEmpty) {
      state = state.copyWith(searchQuery: '', searchResults: const []);
      return;
    }
    state = state.copyWith(searchQuery: query, searchLoading: true);
    final result = await _repository.searchUsers(query);
    if (generation != _sessionGeneration || state.searchQuery != query) return;
    state = result.when(
      success: (items) =>
          state.copyWith(searchResults: items, searchLoading: false),
      failure: (failure) =>
          state.copyWith(searchLoading: false, searchFailure: failure),
    );
  }

  Future<void> loadFriends({bool force = false, bool more = false}) async {
    final generation = _sessionGeneration;
    if (state.friendsLoading || (more && !state.friendsHasMore)) return;
    final page = more ? state.friendsPage + 1 : 1;
    state = state.copyWith(friendsLoading: true);
    final result = await _repository.getFriends(page, pageSize);
    if (generation != _sessionGeneration) return;
    state = result.when(
      success: (value) => state.copyWith(
        friends: _dedupeBy(
          more ? [...state.friends, ...value.items] : value.items,
          (item) => item.friendshipId,
        ),
        friendsPage: value.pageNumber,
        friendsHasMore: value.hasNextPage,
        friendsLoading: false,
      ),
      failure: (failure) =>
          state.copyWith(friendsLoading: false, friendsFailure: failure),
    );
  }

  Future<void> loadRequests({bool force = false}) async {
    final generation = _sessionGeneration;
    if (state.requestsLoading) return;
    state = state.copyWith(requestsLoading: true);
    final results = await Future.wait([
      _repository.getIncomingRequests(1, pageSize),
      _repository.getOutgoingRequests(1, pageSize),
    ]);
    if (generation != _sessionGeneration) return;
    final incoming = results[0];
    final outgoing = results[1];
    final failure = incoming.failureOrNull ?? outgoing.failureOrNull;
    state = failure == null
        ? state.copyWith(
            incoming: incoming.valueOrNull!.items,
            incomingPage: incoming.valueOrNull!.pageNumber,
            incomingHasMore: incoming.valueOrNull!.hasNextPage,
            outgoing: outgoing.valueOrNull!.items,
            outgoingPage: outgoing.valueOrNull!.pageNumber,
            outgoingHasMore: outgoing.valueOrNull!.hasNextPage,
            requestsLoading: false,
          )
        : state.copyWith(requestsLoading: false, requestsFailure: failure);
  }

  Future<void> loadMoreRequests({required bool incoming}) async {
    final generation = _sessionGeneration;
    if (state.requestsLoading ||
        (incoming ? !state.incomingHasMore : !state.outgoingHasMore)) {
      return;
    }
    state = state.copyWith(requestsLoading: true);
    final page = incoming ? state.incomingPage + 1 : state.outgoingPage + 1;
    final result = incoming
        ? await _repository.getIncomingRequests(page, pageSize)
        : await _repository.getOutgoingRequests(page, pageSize);
    if (generation != _sessionGeneration) return;
    state = result.when(
      success: (value) => incoming
          ? state.copyWith(
              incoming: _dedupeBy([
                ...state.incoming,
                ...value.items,
              ], (item) => item.id),
              incomingPage: value.pageNumber,
              incomingHasMore: value.hasNextPage,
              requestsLoading: false,
            )
          : state.copyWith(
              outgoing: _dedupeBy([
                ...state.outgoing,
                ...value.items,
              ], (item) => item.id),
              outgoingPage: value.pageNumber,
              outgoingHasMore: value.hasNextPage,
              requestsLoading: false,
            ),
      failure: (failure) =>
          state.copyWith(requestsLoading: false, requestsFailure: failure),
    );
  }

  Future<void> loadBlocked({bool more = false}) async {
    final generation = _sessionGeneration;
    if (state.blockedLoading || (more && !state.blockedHasMore)) return;
    final page = more ? state.blockedPage + 1 : 1;
    state = state.copyWith(blockedLoading: true);
    final result = await _repository.getBlockedUsers(page, pageSize);
    if (generation != _sessionGeneration) return;
    state = result.when(
      success: (value) => state.copyWith(
        blocked: _dedupeBy(
          more ? [...state.blocked, ...value.items] : value.items,
          (item) => item.blockId,
        ),
        blockedPage: value.pageNumber,
        blockedHasMore: value.hasNextPage,
        blockedLoading: false,
      ),
      failure: (failure) =>
          state.copyWith(blockedLoading: false, blockedFailure: failure),
    );
  }

  Future<void> loadInbox({bool force = false, bool more = false}) async {
    final generation = _sessionGeneration;
    if (state.inboxLoading || (more && !state.inboxHasMore)) return;
    final page = more ? state.inboxPage + 1 : 1;
    state = state.copyWith(inboxLoading: true);
    final result = await _repository.getConversations(page, pageSize);
    if (generation != _sessionGeneration) return;
    state = result.when(
      success: (value) {
        _rememberMessages(
          value.items.map((item) => item.lastMessage).whereType<ChatMessage>(),
        );
        return state.copyWith(
          conversations: _dedupeBy(
            more ? [...state.conversations, ...value.items] : value.items,
            (item) => item.id,
          ),
          inboxPage: value.pageNumber,
          inboxHasMore: value.hasNextPage,
          inboxLoading: false,
        );
      },
      failure: (failure) =>
          state.copyWith(inboxLoading: false, inboxFailure: failure),
    );
    if (result.isSuccess && !more) await _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    final generation = _sessionGeneration;
    var page = 1;
    var total = 0;
    while (true) {
      final result = await _repository.getConversations(page, 100);
      if (generation != _sessionGeneration) return;
      final value = result.valueOrNull;
      if (value == null) return;
      total += value.items.fold(0, (sum, item) => sum + item.unreadCount);
      if (!value.hasNextPage) break;
      page++;
    }
    if (generation == _sessionGeneration) {
      state = state.copyWith(unreadMessages: total);
    }
  }

  Future<Result<void>> sendFriendRequest(String userId) =>
      _mutation(userId, () async {
        final generation = _sessionGeneration;
        final result = await _repository.sendFriendRequest(userId);
        if (generation != _sessionGeneration) {
          return result.when(
            success: (_) => const Result.success(null),
            failure: Result.failure,
          );
        }
        if (result.isSuccess) {
          _setSearchStatus(userId, SocialStatus.pendingSent);
          await loadRequests(force: true);
        }
        return result.when(
          success: (_) => const Result.success(null),
          failure: Result.failure,
        );
      });

  Future<Result<void>> acceptRequest(FriendRequest request) => _requestMutation(
    request,
    _repository.acceptFriendRequest,
    SocialStatus.friends,
  );
  Future<Result<void>> rejectRequest(FriendRequest request) => _requestMutation(
    request,
    _repository.rejectFriendRequest,
    SocialStatus.none,
  );

  Future<Result<void>> cancelRequest(FriendRequest request) =>
      _mutation(request.id, () async {
        final generation = _sessionGeneration;
        final result = await _repository.cancelFriendRequest(request.id);
        if (generation != _sessionGeneration) return result;
        if (result.isSuccess) {
          _setSearchStatus(request.addresseeUserId, SocialStatus.none);
          await loadRequests(force: true);
        }
        return result;
      });

  Future<Result<void>> _requestMutation(
    FriendRequest request,
    Future<Result<FriendRequest>> Function(String) action,
    SocialStatus status,
  ) => _mutation(request.id, () async {
    final generation = _sessionGeneration;
    final result = await action(request.id);
    if (generation != _sessionGeneration) {
      return result.when(
        success: (_) => const Result.success(null),
        failure: Result.failure,
      );
    }
    if (result.isSuccess) {
      final counterpart = request.user?.userId ?? request.requesterUserId;
      _setSearchStatus(counterpart, status);
      await Future.wait([loadRequests(force: true), loadFriends(force: true)]);
    }
    return result.when(
      success: (_) => const Result.success(null),
      failure: Result.failure,
    );
  });

  Future<Result<void>> blockUser(String userId) => _mutation(userId, () async {
    final generation = _sessionGeneration;
    final result = await _repository.blockUser(userId);
    if (generation != _sessionGeneration) return result;
    if (result.isSuccess) {
      state = state.copyWith(
        friends: state.friends
            .where((item) => item.user.userId != userId)
            .toList(),
        incoming: state.incoming
            .where((item) => item.user?.userId != userId)
            .toList(),
        outgoing: state.outgoing
            .where((item) => item.user?.userId != userId)
            .toList(),
        searchResults: state.searchResults
            .where((item) => item.userId != userId)
            .toList(),
        conversations: state.conversations
            .where((item) => item.counterpart.userId != userId)
            .toList(),
      );
      await Future.wait([loadBlocked(), loadInbox(force: true)]);
    }
    return result;
  });

  Future<Result<void>> unblockUser(String userId) =>
      _mutation(userId, () async {
        final generation = _sessionGeneration;
        final result = await _repository.unblockUser(userId);
        if (generation != _sessionGeneration) return result;
        if (result.isSuccess) {
          state = state.copyWith(
            blocked: state.blocked
                .where((item) => item.user.userId != userId)
                .toList(),
          );
          await loadInbox(force: true);
        }
        return result;
      });

  Future<Result<Conversation>> createConversation(String userId) async {
    final generation = _sessionGeneration;
    if (state.busyIds.contains(userId)) {
      return const Result.failure(
        UnknownFailure('La conversación ya se está abriendo.'),
      );
    }
    _setBusy(userId, true);
    final result = await _repository.createConversation(userId);
    if (generation != _sessionGeneration) return result;
    _setBusy(userId, false);
    if (result.valueOrNull case final conversation?) {
      state = state.copyWith(
        conversations: _dedupeBy([
          conversation,
          ...state.conversations,
        ], (item) => item.id),
      );
    }
    return result;
  }

  Future<void> enterConversation(String id) async {
    state = state.copyWith(activeConversationId: id);
    await loadConversation(id);
  }

  void leaveConversation(String id) {
    if (state.activeConversationId == id) {
      final chats = {...state.chats}..remove(id);
      state = state.copyWith(chats: chats, clearActiveConversation: true);
    }
  }

  Future<void> loadConversation(String id, {bool force = false}) async {
    final generation = _sessionGeneration;
    final existing = state.chats[id] ?? const ConversationMessagesState();
    if (existing.isLoading) return;
    _setChat(id, existing.copyWith(isLoading: true, clearFailure: true));
    final results = await Future.wait([
      _repository.getConversation(id),
      _repository.getMessages(id, pageSize: messagePageSize),
    ]);
    if (generation != _sessionGeneration) return;
    final conversationResult = results[0] as Result<Conversation>;
    final messagesResult = results[1] as Result<MessagePage>;
    final failure =
        conversationResult.failureOrNull ?? messagesResult.failureOrNull;
    final latest = state.chats[id] ?? existing;
    if (failure != null) {
      _setChat(id, latest.copyWith(isLoading: false, failure: failure));
      return;
    }
    final page = messagesResult.valueOrNull!;
    _rememberMessages(page.items);
    _setChat(
      id,
      latest.copyWith(
        conversation: conversationResult.valueOrNull,
        messages: mergeMessages(latest.messages, page.items),
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoading: false,
        clearFailure: true,
      ),
    );
    await markRead(id);
  }

  Future<void> loadOlderMessages(String id) async {
    final generation = _sessionGeneration;
    final chat = state.chats[id];
    if (chat == null ||
        chat.isLoadingMore ||
        !chat.hasMore ||
        chat.nextCursor == null) {
      return;
    }
    _setChat(id, chat.copyWith(isLoadingMore: true));
    final result = await _repository.getMessages(
      id,
      pageSize: messagePageSize,
      cursor: chat.nextCursor,
    );
    if (generation != _sessionGeneration) return;
    final latest = state.chats[id] ?? chat;
    result.when(
      success: (page) {
        _rememberMessages(page.items);
        _setChat(
          id,
          latest.copyWith(
            messages: mergeMessages(latest.messages, page.items),
            nextCursor: page.nextCursor,
            hasMore: page.hasMore,
            isLoadingMore: false,
          ),
        );
      },
      failure: (_) => _setChat(id, latest.copyWith(isLoadingMore: false)),
    );
  }

  Future<Result<void>> sendMessage(String id, String rawContent) async {
    final generation = _sessionGeneration;
    final content = rawContent.trim();
    if (content.isEmpty) {
      return const Result.failure(ValidationFailure('Escribe un mensaje.'));
    }
    if (content.length > 2000) {
      return const Result.failure(
        ValidationFailure('El mensaje no puede superar 2000 caracteres.'),
      );
    }
    final chat = state.chats[id] ?? const ConversationMessagesState();
    if (chat.isSending) {
      return const Result.failure(
        ValidationFailure('Espera a que se envíe el mensaje.'),
      );
    }
    _setChat(id, chat.copyWith(isSending: true, clearFailure: true));
    final result = await _repository.sendMessage(id, content);
    if (generation != _sessionGeneration) {
      return result.when(
        success: (_) => const Result.success(null),
        failure: Result.failure,
      );
    }
    final latest = state.chats[id] ?? chat;
    if (result.valueOrNull case final message?) {
      _rememberMessage(message.id);
      _setChat(
        id,
        latest.copyWith(
          messages: mergeMessages(latest.messages, [message]),
          isSending: false,
        ),
      );
      _upsertConversationMessage(message, incrementUnread: false);
      return const Result.success(null);
    }
    final failure = result.failureOrNull!;
    final unavailable =
        failure is ServerFailure &&
        (failure.errorCode == 'Social.Blocked' ||
            failure.errorCode == 'Social.NotFriends' ||
            failure.errorCode == 'Social.NotFound');
    _setChat(
      id,
      latest.copyWith(
        isSending: false,
        canSend: !unavailable,
        failure: unavailable ? failure : null,
      ),
    );
    if (unavailable) unawaited(loadInbox(force: true));
    return Result.failure(failure);
  }

  Future<void> markRead(String id) async {
    final generation = _sessionGeneration;
    final previousUnread = state.conversations
        .where((item) => item.id == id)
        .fold(0, (sum, item) => sum + item.unreadCount);
    final result = await _repository.markConversationRead(id);
    if (generation != _sessionGeneration) return;
    if (result.isSuccess) {
      state = state.copyWith(
        conversations: state.conversations
            .map((item) => item.id == id ? item.copyWith(unreadCount: 0) : item)
            .toList(growable: false),
        unreadMessages: (state.unreadMessages - previousUnread).clamp(
          0,
          1 << 31,
        ),
      );
    }
  }

  Future<Result<void>> _mutation(
    String id,
    Future<Result<void>> Function() action,
  ) async {
    final generation = _sessionGeneration;
    if (state.busyIds.contains(id)) {
      return const Result.failure(
        ValidationFailure('Esta acción ya está en proceso.'),
      );
    }
    _setBusy(id, true);
    final result = await action();
    if (generation == _sessionGeneration) _setBusy(id, false);
    return result;
  }

  void _setBusy(String id, bool busy) {
    final ids = {...state.busyIds};
    busy ? ids.add(id) : ids.remove(id);
    state = state.copyWith(busyIds: ids);
  }

  void _setSearchStatus(String userId, SocialStatus status) {
    state = state.copyWith(
      searchResults: state.searchResults
          .map(
            (item) => item.userId == userId
                ? item.copyWith(socialStatus: status)
                : item,
          )
          .toList(growable: false),
    );
  }

  void _setChat(String id, ConversationMessagesState value) {
    state = state.copyWith(chats: {...state.chats, id: value});
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    if (ref.read(authStateControllerProvider).status !=
        AuthStatus.authenticated) {
      return;
    }
    try {
      switch (event.name) {
        case 'social.friend_request.received':
          final request = FriendRequestDto.fromJson(event.data).toDomain();
          state = state.copyWith(
            incoming: _dedupeBy([
              request,
              ...state.incoming,
            ], (item) => item.id),
          );
          unawaited(loadRequests(force: true));
        case 'social.friend_request.accepted':
          final request = FriendRequestDto.fromJson(event.data).toDomain();
          _setSearchStatus(request.addresseeUserId, SocialStatus.friends);
          unawaited(
            Future.wait([loadRequests(force: true), loadFriends(force: true)]),
          );
        case 'chat.message.received':
          final message = ChatMessageDto.fromJson(event.data).toDomain();
          if (!_rememberMessage(message.id)) return;
          final chat = state.chats[message.conversationId];
          if (chat != null) {
            _setChat(
              message.conversationId,
              chat.copyWith(messages: mergeMessages(chat.messages, [message])),
            );
          }
          final isOpen = state.activeConversationId == message.conversationId;
          _upsertConversationMessage(message, incrementUnread: !isOpen);
          if (isOpen) unawaited(markRead(message.conversationId));
          if (!state.conversations.any(
            (item) => item.id == message.conversationId,
          )) {
            unawaited(loadInbox(force: true));
          }
        case 'chat.message.read':
          readReceipt(
            event.data,
          ); // Validate exact contract; no invented read UX.
      }
    } on Object {
      // Unknown or malformed events never terminate the shared connection.
    }
  }

  bool _rememberMessage(String id) {
    final added = _knownMessageIds.add(id);
    if (_knownMessageIds.length > 5000) {
      _knownMessageIds.remove(_knownMessageIds.first);
    }
    return added;
  }

  void _rememberMessages(Iterable<ChatMessage> messages) {
    for (final message in messages) {
      _rememberMessage(message.id);
    }
  }

  void _upsertConversationMessage(
    ChatMessage message, {
    required bool incrementUnread,
  }) {
    final items =
        state.conversations
            .map((conversation) {
              if (conversation.id != message.conversationId) {
                return conversation;
              }
              return conversation.copyWith(
                lastMessage: message,
                lastMessageAtUtc: message.createdAtUtc,
                unreadCount: incrementUnread
                    ? conversation.unreadCount + 1
                    : conversation.unreadCount,
              );
            })
            .toList(growable: false)
          ..sort(
            (a, b) => (b.lastMessageAtUtc ?? b.createdAtUtc).compareTo(
              a.lastMessageAtUtc ?? a.createdAtUtc,
            ),
          );
    state = state.copyWith(
      conversations: items,
      unreadMessages: incrementUnread
          ? state.unreadMessages + 1
          : state.unreadMessages,
    );
  }
}

final socialControllerProvider =
    NotifierProvider<SocialController, SocialState>(SocialController.new);

final socialSessionCoordinatorProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authStateControllerProvider, (previous, next) {
    final controller = ref.read(socialControllerProvider.notifier);
    if (next.status == AuthStatus.authenticated &&
        previous?.status != AuthStatus.authenticated) {
      controller.initializeRealtime();
      unawaited(controller.reconcile());
    } else if (next.status == AuthStatus.unauthenticated &&
        previous?.status != AuthStatus.unauthenticated) {
      controller.clear();
    }
  }, fireImmediately: true);
});

List<T> _dedupeBy<T>(List<T> items, String Function(T) id) {
  final seen = <String>{};
  return items.where((item) => seen.add(id(item))).toList(growable: false);
}

/// Central message identity reconciliation for POST, REST and realtime.
List<ChatMessage> mergeMessages(
  List<ChatMessage> current,
  List<ChatMessage> incoming,
) {
  final byId = <String, ChatMessage>{for (final item in current) item.id: item};
  for (final item in incoming) {
    byId[item.id] = item;
  }
  final result = byId.values.toList(growable: false)
    ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
  return result;
}
