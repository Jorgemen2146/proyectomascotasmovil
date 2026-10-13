import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../authentication/application/auth_state_controller.dart';
import '../../application/providers.dart';
import '../../application/social_state.dart';
import '../../domain/entities/social.dart';

class SocialSearchPage extends ConsumerStatefulWidget {
  const SocialSearchPage({super.key});
  @override
  ConsumerState<SocialSearchPage> createState() => _SocialSearchPageState();
}

class _SocialSearchPageState extends ConsumerState<SocialSearchPage> {
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => ref.read(socialControllerProvider.notifier).search(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialControllerProvider);
    return _SocialScaffold(
      title: 'Encontrar amigos',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.section),
            child: TextField(
              key: const Key('socialSearchField'),
              autofocus: true,
              onChanged: _changed,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre',
                prefixIcon: Icon(AppIcons.search),
              ),
            ),
          ),
          Expanded(child: _searchBody(state)),
        ],
      ),
    );
  }

  Widget _searchBody(SocialState state) {
    if (state.searchQuery.isEmpty) {
      return const EmptyState(
        icon: AppIcons.search,
        title: 'Encuentra a tus amigos',
        message: 'Escribe un nombre para comenzar.',
      );
    }
    if (state.searchLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.searchFailure case final failure?) {
      return ErrorState(
        message: failure.message,
        onRetry: () => ref
            .read(socialControllerProvider.notifier)
            .search(state.searchQuery),
      );
    }
    if (state.searchResults.isEmpty) {
      return const EmptyState(
        icon: AppIcons.search,
        title: 'Sin resultados',
        message: 'Prueba con otro nombre.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.section,
        0,
        AppSpacing.section,
        AppSpacing.lg,
      ),
      itemCount: state.searchResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.compact),
      itemBuilder: (context, index) => _UserCard(
        user: state.searchResults[index],
        trailing: _SearchAction(user: state.searchResults[index]),
      ),
    );
  }
}

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});
  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(socialControllerProvider.notifier).loadFriends(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialControllerProvider);
    return _SocialScaffold(
      title: 'Mis amigos',
      actions: [
        IconButton(
          tooltip: 'Buscar usuarios',
          onPressed: () => context.push(AppRoutes.socialSearch),
          icon: const Icon(AppIcons.search),
        ),
      ],
      child: _pagedBody<Friendship>(
        items: state.friends,
        loading: state.friendsLoading,
        failure: state.friendsFailure,
        hasMore: state.friendsHasMore,
        emptyIcon: AppIcons.friends,
        emptyTitle: 'Aún no tienes amigos',
        emptyMessage: 'Busca personas y envía tu primera solicitud.',
        onRefresh: () => ref
            .read(socialControllerProvider.notifier)
            .loadFriends(force: true),
        onMore: () =>
            ref.read(socialControllerProvider.notifier).loadFriends(more: true),
        itemBuilder: (friendship) => _UserCard(
          user: friendship.user,
          trailing: PopupMenuButton<String>(
            icon: const Icon(AppIcons.more),
            onSelected: (value) => value == 'message'
                ? _openConversation(context, ref, friendship.user.userId)
                : _confirmBlock(context, ref, friendship.user),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'message', child: Text('Mensaje')),
              PopupMenuItem(value: 'block', child: Text('Bloquear')),
            ],
          ),
        ),
      ),
    );
  }
}

class FriendRequestsPage extends ConsumerStatefulWidget {
  const FriendRequestsPage({super.key});
  @override
  ConsumerState<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends ConsumerState<FriendRequestsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(socialControllerProvider.notifier).loadRequests(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialControllerProvider);
    final Widget body;
    if (state.requestsLoading &&
        state.incoming.isEmpty &&
        state.outgoing.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.requestsFailure != null) {
      body = ErrorState(
        message: state.requestsFailure!.message,
        onRetry: () => ref
            .read(socialControllerProvider.notifier)
            .loadRequests(force: true),
      );
    } else {
      body = TabBarView(
        children: [
          _RequestList(
            items: state.incoming,
            incoming: true,
            hasMore: state.incomingHasMore,
          ),
          _RequestList(
            items: state.outgoing,
            incoming: false,
            hasMore: state.outgoingHasMore,
          ),
        ],
      );
    }
    return DefaultTabController(
      length: 2,
      child: _SocialScaffold(
        title: 'Solicitudes',
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Recibidas'),
            Tab(text: 'Enviadas'),
          ],
        ),
        child: body,
      ),
    );
  }
}

class BlockedUsersPage extends ConsumerStatefulWidget {
  const BlockedUsersPage({super.key});
  @override
  ConsumerState<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends ConsumerState<BlockedUsersPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(socialControllerProvider.notifier).loadBlocked(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialControllerProvider);
    return _SocialScaffold(
      title: 'Usuarios bloqueados',
      child: _pagedBody<BlockedUser>(
        items: state.blocked,
        loading: state.blockedLoading,
        failure: state.blockedFailure,
        hasMore: state.blockedHasMore,
        emptyIcon: AppIcons.blocked,
        emptyTitle: 'No hay usuarios bloqueados',
        emptyMessage: 'Las personas que bloquees aparecerán aquí.',
        onRefresh: () =>
            ref.read(socialControllerProvider.notifier).loadBlocked(),
        onMore: () =>
            ref.read(socialControllerProvider.notifier).loadBlocked(more: true),
        itemBuilder: (blocked) => _UserCard(
          user: blocked.user,
          trailing: OutlinedButton(
            onPressed: state.busyIds.contains(blocked.user.userId)
                ? null
                : () async {
                    final result = await ref
                        .read(socialControllerProvider.notifier)
                        .unblockUser(blocked.user.userId);
                    if (!context.mounted) return;
                    _showResult(
                      context,
                      result.failureOrNull,
                      'Usuario desbloqueado.',
                    );
                  },
            child: const Text('Desbloquear'),
          ),
        ),
      ),
    );
  }
}

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});
  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(socialControllerProvider.notifier).loadInbox(force: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialControllerProvider);
    return _SocialScaffold(
      title: 'Mensajes',
      child: _pagedBody<Conversation>(
        items: state.conversations,
        loading: state.inboxLoading,
        failure: state.inboxFailure,
        hasMore: state.inboxHasMore,
        emptyIcon: AppIcons.messages,
        emptyTitle: 'Aún no tienes conversaciones',
        emptyMessage: 'Inicia una conversación desde tu lista de amigos.',
        onRefresh: () =>
            ref.read(socialControllerProvider.notifier).loadInbox(force: true),
        onMore: () =>
            ref.read(socialControllerProvider.notifier).loadInbox(more: true),
        itemBuilder: (conversation) => AppCard(
          onTap: () => context.push(AppRoutes.conversation(conversation.id)),
          child: Row(
            children: [
              _SocialAvatar(user: conversation.counterpart),
              const SizedBox(width: AppSpacing.compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.counterpart.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      conversation.lastMessage?.content ??
                          'Conversación iniciada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _time(conversation.lastMessageAtUtc),
                    style: AppTypography.small,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (conversation.unreadCount > 0)
                    _CountBadge(count: conversation.unreadCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.conversationId});
  final String conversationId;
  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(
      () => ref
          .read(socialControllerProvider.notifier)
          .enterConversation(widget.conversationId),
    );
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 180) {
      unawaited(
        ref
            .read(socialControllerProvider.notifier)
            .loadOlderMessages(widget.conversationId),
      );
    }
  }

  @override
  void dispose() {
    ref
        .read(socialControllerProvider.notifier)
        .leaveConversation(widget.conversationId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialControllerProvider);
    final chat =
        state.chats[widget.conversationId] ?? const ConversationMessagesState();
    final user = chat.conversation?.counterpart;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if (user != null) _SocialAvatar(user: user, size: 36),
            if (user != null) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                user?.displayName ?? 'Conversación',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (user != null)
            PopupMenuButton<String>(
              icon: const Icon(AppIcons.more),
              onSelected: (_) async {
                final blocked = await _confirmBlock(context, ref, user);
                if (blocked && context.mounted) context.pop();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'block', child: Text('Bloquear usuario')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _messagesBody(chat)),
            _Composer(
              controller: _messageController,
              sending: chat.isSending,
              enabled:
                  chat.conversation != null &&
                  !chat.isLoading &&
                  chat.failure == null &&
                  chat.canSend &&
                  !(user != null && state.busyIds.contains(user.userId)),
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _messagesBody(ConversationMessagesState chat) {
    if (chat.isLoading && chat.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chat.failure case final failure? when chat.messages.isEmpty) {
      return ErrorState(
        message: failure.message,
        onRetry: () => ref
            .read(socialControllerProvider.notifier)
            .loadConversation(widget.conversationId, force: true),
      );
    }
    final currentUserId = ref.watch(authStateControllerProvider).user?.id;
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(AppSpacing.section),
      itemCount: chat.messages.length + (chat.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chat.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final message = chat.messages[index];
        return _MessageBubble(
          message: message,
          mine: message.senderUserId == currentUserId,
        );
      },
    );
  }

  Future<void> _send() async {
    final text = _messageController.text;
    final result = await ref
        .read(socialControllerProvider.notifier)
        .sendMessage(widget.conversationId, text);
    if (!mounted) return;
    if (result.isSuccess) {
      _messageController.clear();
      if (_scrollController.hasClients) {
        unawaited(
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          ),
        );
      }
    } else {
      AppSnackBar.showError(context, result.failureOrNull!.message);
    }
  }
}

class _SearchAction extends ConsumerWidget {
  const _SearchAction({required this.user});
  final SocialUser user;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(
      socialControllerProvider.select(
        (state) => state.busyIds.contains(user.userId),
      ),
    );
    return switch (user.socialStatus ?? SocialStatus.none) {
      SocialStatus.none => FilledButton(
        onPressed: busy
            ? null
            : () async {
                final result = await ref
                    .read(socialControllerProvider.notifier)
                    .sendFriendRequest(user.userId);
                if (!context.mounted) return;
                _showResult(
                  context,
                  result.failureOrNull,
                  'Solicitud enviada.',
                );
              },
        child: const Text('Agregar'),
      ),
      SocialStatus.pendingSent => const Text('Solicitud enviada'),
      SocialStatus.pendingReceived => TextButton(
        onPressed: () => context.push(AppRoutes.friendRequests),
        child: const Text('Responder'),
      ),
      SocialStatus.friends => TextButton(
        onPressed: busy
            ? null
            : () => _openConversation(context, ref, user.userId),
        child: const Text('Mensaje'),
      ),
    };
  }
}

class _RequestList extends ConsumerWidget {
  const _RequestList({
    required this.items,
    required this.incoming,
    this.hasMore = false,
  });
  final List<FriendRequest> items;
  final bool incoming;
  final bool hasMore;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return EmptyState(
        icon: AppIcons.personAdd,
        title: incoming
            ? 'Sin solicitudes recibidas'
            : 'Sin solicitudes enviadas',
        message: incoming
            ? 'Las nuevas solicitudes aparecerán aquí.'
            : 'Busca usuarios para conectar con ellos.',
      );
    }
    final busyIds = ref.watch(
      socialControllerProvider.select((state) => state.busyIds),
    );
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(socialControllerProvider.notifier).loadRequests(force: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.section),
        itemCount: items.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.compact),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return Center(
              child: TextButton(
                onPressed: () => ref
                    .read(socialControllerProvider.notifier)
                    .loadMoreRequests(incoming: incoming),
                child: const Text('Cargar más'),
              ),
            );
          }
          final request = items[index];
          final user =
              request.user ??
              SocialUser(
                userId: incoming
                    ? request.requesterUserId
                    : request.addresseeUserId,
                displayName: 'Usuario',
              );
          final busy = busyIds.contains(request.id);
          return _UserCard(
            user: user,
            subtitle: _date(request.createdAtUtc),
            trailing: incoming
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Rechazar',
                        onPressed: busy
                            ? null
                            : () =>
                                  _requestAction(context, ref, request, false),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Aceptar',
                        onPressed: busy
                            ? null
                            : () => _requestAction(context, ref, request, true),
                        icon: const Icon(Icons.check_rounded),
                      ),
                    ],
                  )
                : TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            final result = await ref
                                .read(socialControllerProvider.notifier)
                                .cancelRequest(request);
                            if (!context.mounted) return;
                            _showResult(
                              context,
                              result.failureOrNull,
                              'Solicitud cancelada.',
                            );
                          },
                    child: const Text('Cancelar'),
                  ),
          );
        },
      ),
    );
  }
}

class _SocialScaffold extends StatelessWidget {
  const _SocialScaffold({
    required this.title,
    required this.child,
    this.actions,
    this.bottom,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions, bottom: bottom),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: child,
      ),
    ),
  );
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.trailing, this.subtitle});
  final SocialUser user;
  final Widget trailing;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        _SocialAvatar(user: user),
        const SizedBox(width: AppSpacing.compact),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle,
              ),
              if (subtitle != null)
                Text(subtitle!, style: AppTypography.caption),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: trailing),
      ],
    ),
  );
}

class _SocialAvatar extends StatelessWidget {
  const _SocialAvatar({required this.user, this.size = 48});
  final SocialUser user;
  final double size;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: size,
      height: size,
      child: AppNetworkImage(
        url: user.profilePhotoUrl,
        width: size,
        height: size,
      ),
    ),
  );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: const BoxDecoration(
      color: AppColors.primary,
      shape: BoxShape.circle,
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;
  @override
  Widget build(BuildContext context) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .76,
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.compact,
      ),
      decoration: BoxDecoration(
        color: mine ? AppColors.primary : AppColors.primarySoft,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.lg),
          topRight: const Radius.circular(AppRadius.lg),
          bottomLeft: Radius.circular(mine ? AppRadius.lg : AppRadius.sm),
          bottomRight: Radius.circular(mine ? AppRadius.sm : AppRadius.lg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.content,
            style: AppTypography.body.copyWith(
              color: mine ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _time(message.createdAtUtc),
            style: AppTypography.small.copyWith(
              color: mine
                  ? Colors.white.withValues(alpha: .78)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.section,
        AppSpacing.sm,
        AppSpacing.section,
        AppSpacing.sm + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('messageComposer'),
              controller: controller,
              minLines: 1,
              maxLines: 5,
              maxLength: 2000,
              enabled: enabled,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            key: const Key('sendMessageButton'),
            tooltip: 'Enviar',
            onPressed: sending || !enabled ? null : onSend,
            icon: sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(AppIcons.send),
          ),
        ],
      ),
    ),
  );
}

Widget _pagedBody<T>({
  required List<T> items,
  required bool loading,
  required AppFailure? failure,
  required bool hasMore,
  required IconData emptyIcon,
  required String emptyTitle,
  required String emptyMessage,
  required Future<void> Function() onRefresh,
  required VoidCallback onMore,
  required Widget Function(T item) itemBuilder,
}) {
  if (loading && items.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }
  if (failure != null && items.isEmpty) {
    return ErrorState(message: failure.message, onRetry: onRefresh);
  }
  if (items.isEmpty) {
    return EmptyState(
      icon: emptyIcon,
      title: emptyTitle,
      message: emptyMessage,
    );
  }
  return RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.section),
      itemCount: items.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.compact),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Center(
            child: TextButton(
              onPressed: loading ? null : onMore,
              child: Text(loading ? 'Cargando…' : 'Cargar más'),
            ),
          );
        }
        return itemBuilder(items[index]);
      },
    ),
  );
}

Future<void> _openConversation(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final result = await ref
      .read(socialControllerProvider.notifier)
      .createConversation(userId);
  if (!context.mounted) return;
  final conversation = result.valueOrNull;
  if (conversation != null) {
    context.push(AppRoutes.conversation(conversation.id));
  } else {
    AppSnackBar.showError(context, result.failureOrNull!.message);
  }
}

Future<bool> _confirmBlock(
  BuildContext context,
  WidgetRef ref,
  SocialUser user,
) async {
  final confirmed = await AppDialog.confirm(
    context,
    title: '¿Bloquear a ${user.displayName}?',
    message: 'Dejarán de ser amigos y no podrán enviarse mensajes.',
    confirmLabel: 'Bloquear',
    cancelLabel: 'Cancelar',
    isDestructive: true,
  );
  if (!confirmed) return false;
  final result = await ref
      .read(socialControllerProvider.notifier)
      .blockUser(user.userId);
  if (!context.mounted) return result.isSuccess;
  _showResult(context, result.failureOrNull, 'Usuario bloqueado.');
  return result.isSuccess;
}

Future<void> _requestAction(
  BuildContext context,
  WidgetRef ref,
  FriendRequest request,
  bool accept,
) async {
  final controller = ref.read(socialControllerProvider.notifier);
  final result = accept
      ? await controller.acceptRequest(request)
      : await controller.rejectRequest(request);
  if (!context.mounted) return;
  _showResult(
    context,
    result.failureOrNull,
    accept ? 'Solicitud aceptada.' : 'Solicitud rechazada.',
  );
}

void _showResult(BuildContext context, AppFailure? failure, String success) {
  failure == null
      ? AppSnackBar.showSuccess(context, success)
      : AppSnackBar.showError(context, failure.message);
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String _time(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
