import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../application/notifications_state.dart';
import '../../application/providers.dart';
import '../../domain/entities/notification.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreIfNeeded);
    Future.microtask(() {
      final controller = ref.read(notificationsControllerProvider.notifier);
      controller.loadNotifications();
      controller.refreshUnreadCount(silent: true);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreIfNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 240) {
      ref.read(notificationsControllerProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              key: const Key('markAllReadButton'),
              onPressed: state.isMarkingAll ? null : _markAllAsRead,
              child: const Text('Marcar todas como leídas'),
            ),
        ],
      ),
      body: SafeArea(child: _body(state)),
    );
  }

  Widget _body(NotificationsState state) {
    if (state.isLoadingList && state.items.isEmpty) {
      return const AppLoadingIndicator();
    }
    if (state.listFailure != null && state.items.isEmpty) {
      return ErrorState(
        title: 'No pudimos cargar tus notificaciones',
        message: 'Revisa tu conexión e intenta nuevamente.',
        onRetry: () => ref
            .read(notificationsControllerProvider.notifier)
            .loadNotifications(force: true),
      );
    }
    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Todo está al día',
              message:
                  'No tienes notificaciones pendientes.\n'
                  'Te avisaremos cuando alguna de tus mascotas necesite '
                  'atención.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        key: const Key('notificationsList'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final notification = state.items[index];
          return _NotificationCard(
            notification: notification,
            onTap: () => _openNotification(notification),
          );
        },
      ),
    );
  }

  Future<void> _refresh() async {
    final controller = ref.read(notificationsControllerProvider.notifier);
    await Future.wait([
      controller.loadNotifications(force: true),
      controller.refreshUnreadCount(),
    ]);
  }

  Future<void> _markAllAsRead() async {
    final result = await ref
        .read(notificationsControllerProvider.notifier)
        .markAllAsRead();
    if (!mounted || result.isSuccess) return;
    AppSnackBar.showError(context, result.failureOrNull!.message);
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.isRead) {
      final result = await ref
          .read(notificationsControllerProvider.notifier)
          .markAsRead(notification.notificationId);
      if (!mounted) return;
      if (result.isFailure) {
        AppSnackBar.showError(context, result.failureOrNull!.message);
        return;
      }
    }
    if (!mounted) return;
    final petId = notification.petId;
    if (notification.isVaccination && petId != null) {
      context.push(AppRoutes.healthForPet(petId));
      return;
    }
    if (!notification.isMatching) return;
    final matchId = notification.metadata?.matchId;
    if (matchId != null && matchId.isNotEmpty) {
      context.push(AppRoutes.matchingMatch(matchId));
      return;
    }
    final requestId = notification.metadata?.matchRequestId;
    if (requestId != null && requestId.isNotEmpty) {
      context.push(AppRoutes.matchingRequests);
      return;
    }
    context.push(AppRoutes.matchingRequests);
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _visual(notification.type);
    final petName = notification.metadata?.petName;
    return Material(
      color: notification.isRead
          ? AppColors.surface
          : AppColors.primary.withValues(alpha: 0.045),
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        key: Key('notification-${notification.notificationId}'),
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: notification.isRead
                  ? AppColors.border
                  : AppColors.primary.withValues(alpha: 0.15),
            ),
            boxShadow: AppShadows.subtle,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(visual.icon, color: visual.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.body.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            key: const Key('unreadIndicator'),
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(
                              left: AppSpacing.sm,
                              top: 5,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.message,
                      style: AppTypography.bodySecondary,
                    ),
                    if (petName != null && petName.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        petName,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _formatDateTime(notification.createdAtUtc),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationVisual {
  const _NotificationVisual(this.icon, this.color);
  final IconData icon;
  final Color color;
}

_NotificationVisual _visual(String type) => switch (type) {
  _ when type.startsWith('Matching') => const _NotificationVisual(
    Icons.favorite_outline,
    AppColors.primary,
  ),
  'VaccinationDueSoon' => const _NotificationVisual(
    Icons.event_outlined,
    AppColors.warning,
  ),
  'VaccinationDueToday' => const _NotificationVisual(
    Icons.vaccines_outlined,
    AppColors.primary,
  ),
  'VaccinationOverdue' => const _NotificationVisual(
    Icons.warning_amber_rounded,
    AppColors.error,
  ),
  'VaccinationNotStarted' => const _NotificationVisual(
    Icons.info_outline_rounded,
    AppColors.primary,
  ),
  _ => const _NotificationVisual(
    Icons.notifications_none_rounded,
    AppColors.textSecondary,
  ),
};

String _formatDateTime(DateTime value) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]} ${local.year} · $hour:$minute';
}
