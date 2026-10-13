import 'dart:async';

import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/realtime/realtime_client.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/authentication/application/auth_state.dart';
import 'package:dogplatform/features/authentication/application/auth_state_controller.dart';
import 'package:dogplatform/features/authentication/domain/entities/user.dart';
import 'package:dogplatform/features/notifications/application/providers.dart';
import 'package:dogplatform/features/social/application/providers.dart';
import 'package:dogplatform/features/social/domain/entities/social.dart';
import 'package:dogplatform/features/social/domain/repositories/social_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSocialRepository repository;
  late FakeRealtimeClient realtime;
  late ProviderContainer container;
  late SocialController controller;

  setUp(() {
    repository = FakeSocialRepository();
    realtime = FakeRealtimeClient();
    container = ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(repository),
        realtimeClientProvider.overrideWithValue(realtime),
        authStateControllerProvider.overrideWith(FakeAuthController.new),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(realtime.dispose);
    controller = container.read(socialControllerProvider.notifier);
    controller.initializeRealtime();
  });

  test('POST -> WebSocket -> REST conserva un solo MessageId', () async {
    await controller.loadInbox();
    await controller.enterConversation(conversation.id);

    repository.sendResult = Result.success(message('message-1'));
    expect(
      (await controller.sendMessage(conversation.id, 'Hola')).isSuccess,
      isTrue,
    );
    realtime.emitMessage(message('message-1'));
    await flushEvents();
    repository.messages = [message('message-1')];
    await controller.loadConversation(conversation.id, force: true);

    final chat = container
        .read(socialControllerProvider)
        .chats[conversation.id]!;
    expect(chat.messages.map((item) => item.id), ['message-1']);
    expect(container.read(socialControllerProvider).unreadMessages, 0);
  });

  test('WebSocket -> REST conserva un solo MessageId', () async {
    await controller.loadInbox();
    realtime.emitMessage(message('message-1'));
    await flushEvents();

    repository.messages = [message('message-1')];
    await controller.enterConversation(conversation.id);

    final chat = container
        .read(socialControllerProvider)
        .chats[conversation.id]!;
    expect(chat.messages.map((item) => item.id), ['message-1']);
  });

  test(
    'WebSocket durante carga REST no se pierde por respuesta tardía',
    () async {
      await controller.loadInbox();
      final pending = Completer<Result<MessagePage>>();
      repository.pendingMessages = pending;
      final loading = controller.enterConversation(conversation.id);
      await flushEvents();

      realtime.emitMessage(message('message-4'));
      await flushEvents();
      pending.complete(
        const Result.success(
          MessagePage(items: [], nextCursor: null, hasMore: false),
        ),
      );
      await loading;

      final chat = container
          .read(socialControllerProvider)
          .chats[conversation.id]!;
      expect(chat.messages.map((item) => item.id), ['message-4']);
    },
  );

  test('evento realtime repetido no duplica mensaje ni unread', () async {
    await controller.loadInbox();

    realtime.emitMessage(message('message-1'));
    realtime.emitMessage(message('message-1'));
    await flushEvents();

    final state = container.read(socialControllerProvider);
    expect(state.conversations.single.unreadCount, 1);
    expect(state.unreadMessages, 1);
  });

  test(
    'unread cerrado suma, abrir marca read y abierto no deja badge',
    () async {
      await controller.loadInbox();
      realtime.emitMessage(message('message-1'));
      realtime.emitMessage(message('message-2'));
      await flushEvents();
      expect(container.read(socialControllerProvider).unreadMessages, 2);

      repository.messages = [message('message-2'), message('message-1')];
      await controller.enterConversation(conversation.id);
      expect(container.read(socialControllerProvider).unreadMessages, 0);
      expect(repository.markReadCalls, 1);

      realtime.emitMessage(message('message-3'));
      await flushEvents();
      expect(container.read(socialControllerProvider).unreadMessages, 0);
      expect(repository.markReadCalls, 2);
    },
  );

  test('reconnect corrige unread perdido mediante REST', () async {
    await controller.loadInbox();
    repository.currentConversation = conversation.copyWith(unreadCount: 4);

    realtime.emitConnected();
    await flushEvents();
    await flushEvents();

    expect(container.read(socialControllerProvider).unreadMessages, 4);
  });

  test(
    'respuesta iniciada por A no repuebla estado después de clear',
    () async {
      final pending = Completer<Result<NumberedPage<Conversation>>>();
      repository.pendingConversations = pending;
      final loading = controller.loadInbox();

      controller.clear();
      pending.complete(Result.success(page([conversation])));
      await loading;

      final state = container.read(socialControllerProvider);
      expect(state.conversations, isEmpty);
      expect(state.unreadMessages, 0);

      repository.currentConversation = Conversation(
        id: 'conversation-b',
        counterpart: counterpart,
        createdAtUtc: DateTime.utc(2026, 10, 11),
        unreadCount: 3,
      );
      await controller.loadInbox();
      expect(
        container.read(socialControllerProvider).conversations.single.id,
        'conversation-b',
      );
      expect(container.read(socialControllerProvider).unreadMessages, 3);
    },
  );

  test('reinicializar realtime no registra un listener duplicado', () async {
    await controller.loadInbox();
    controller.initializeRealtime();
    controller.initializeRealtime();

    realtime.emitMessage(message('message-8'));
    await flushEvents();

    expect(container.read(socialControllerProvider).unreadMessages, 1);
    expect(
      container.read(socialControllerProvider).conversations.single.unreadCount,
      1,
    );
  });

  test('Social.Blocked deshabilita envío y limpia inbox', () async {
    await controller.loadInbox();
    await controller.enterConversation(conversation.id);
    repository.sendResult = const Result.failure(
      ServerFailure(
        'Esta conversación está bloqueada.',
        statusCode: 409,
        errorCode: 'Social.Blocked',
      ),
    );

    final result = await controller.sendMessage(conversation.id, 'Otro');

    expect(result.failureOrNull, isA<ServerFailure>());
    expect(
      container.read(socialControllerProvider).chats[conversation.id]!.canSend,
      isFalse,
    );
  });
}

class FakeAuthController extends AuthStateController {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    user: User(id: 'user-b', email: 'b@test.dev', fullName: 'User B'),
  );
}

class FakeRealtimeClient implements RealtimeClient {
  final eventController = StreamController<RealtimeEvent>.broadcast();
  final connectionController = StreamController<void>.broadcast();

  @override
  Stream<RealtimeEvent> get events => eventController.stream;
  @override
  Stream<void> get connections => connectionController.stream;

  void emitMessage(ChatMessage value) => eventController.add(
    RealtimeEvent(
      name: 'chat.message.received',
      data: {
        'id': value.id,
        'conversationId': value.conversationId,
        'senderUserId': value.senderUserId,
        'content': value.content,
        'createdAtUtc': value.createdAtUtc.toIso8601String(),
        'editedAtUtc': null,
        'deletedAtUtc': null,
      },
    ),
  );

  void emitConnected() => connectionController.add(null);

  Future<void> dispose() async {
    await eventController.close();
    await connectionController.close();
  }
}

class FakeSocialRepository implements SocialRepository {
  Conversation currentConversation = conversation;
  List<ChatMessage> messages = const [];
  Result<ChatMessage> sendResult = Result.success(message('sent-default'));
  Completer<Result<NumberedPage<Conversation>>>? pendingConversations;
  Completer<Result<MessagePage>>? pendingMessages;
  int markReadCalls = 0;

  @override
  Future<Result<NumberedPage<Conversation>>> getConversations(
    int pageNumber,
    int pageSize,
  ) async {
    final pending = pendingConversations;
    if (pending != null) {
      pendingConversations = null;
      return pending.future;
    }
    return Result.success(page([currentConversation]));
  }

  @override
  Future<Result<Conversation>> getConversation(String conversationId) async =>
      Result.success(currentConversation);

  @override
  Future<Result<MessagePage>> getMessages(
    String conversationId, {
    required int pageSize,
    MessageCursor? cursor,
  }) async {
    final pending = pendingMessages;
    if (pending != null) {
      pendingMessages = null;
      return pending.future;
    }
    return Result.success(
      MessagePage(items: messages, nextCursor: null, hasMore: false),
    );
  }

  @override
  Future<Result<ChatMessage>> sendMessage(
    String conversationId,
    String content,
  ) async => sendResult;

  @override
  Future<Result<void>> markConversationRead(String conversationId) async {
    markReadCalls++;
    currentConversation = currentConversation.copyWith(unreadCount: 0);
    return const Result.success(null);
  }

  @override
  Future<Result<NumberedPage<FriendRequest>>> getIncomingRequests(
    int page,
    int pageSize,
  ) async => Result.success(emptyPage());

  @override
  Future<Result<NumberedPage<FriendRequest>>> getOutgoingRequests(
    int page,
    int pageSize,
  ) async => Result.success(emptyPage());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const counterpart = SocialUser(userId: 'user-a', displayName: 'User A');
final conversation = Conversation(
  id: 'conversation-1',
  counterpart: counterpart,
  createdAtUtc: DateTime.utc(2026, 10, 10),
  unreadCount: 0,
);

ChatMessage message(String id) => ChatMessage(
  id: id,
  conversationId: conversation.id,
  senderUserId: counterpart.userId,
  content: 'Hola',
  createdAtUtc: DateTime.utc(
    2026,
    10,
    10,
    18,
    58,
    int.parse(id.codeUnitAt(id.length - 1).toString()) % 60,
  ),
);

NumberedPage<T> page<T>(List<T> items) => NumberedPage(
  items: items,
  pageNumber: 1,
  pageSize: 20,
  totalItems: items.length,
  totalPages: items.isEmpty ? 0 : 1,
  hasNextPage: false,
);

NumberedPage<T> emptyPage<T>() => page(const []);

Future<void> flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
