import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/result/result.dart';
import '../../authentication/application/auth_state.dart';
import '../../authentication/application/auth_state_controller.dart';
import '../data/datasources/notifications_remote_data_source.dart';
import '../data/repositories/notifications_repository_impl.dart';
import '../domain/entities/notification.dart';
import '../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
      return NotificationsRemoteDataSource(dio: ref.read(gatewayDioProvider));
    });

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepositoryImpl(
    ref.read(notificationsRemoteDataSourceProvider),
  );
});

abstract class NotificationRealtimeService {
  bool get isAvailable;
  Future<void> connect(
    void Function(AppNotification notification) onNotification,
  );
  Future<void> disconnect();
}

class GatewayBlockedNotificationRealtimeService
    implements NotificationRealtimeService {
  const GatewayBlockedNotificationRealtimeService();

  @override
  bool get isAvailable => false;

  @override
  Future<void> connect(
    void Function(AppNotification notification) onNotification,
  ) async {}

  @override
  Future<void> disconnect() async {}
}

final notificationRealtimeServiceProvider =
    Provider<NotificationRealtimeService>(
      (ref) => const GatewayBlockedNotificationRealtimeService(),
    );

class NotificationsController extends Notifier<NotificationsState> {
  @override
  NotificationsState build() => const NotificationsState();

  Future<void> initialize() async {
    await refreshUnreadCount(silent: true);
    await _startRealtime();
  }

  Future<void> refreshUnreadCount({bool silent = false}) async {
    if (state.isRefreshingUnread) return;
    state = state.copyWith(isRefreshingUnread: true);
    final result = await ref
        .read(notificationsRepositoryProvider)
        .getUnreadCount();
    state = result.when(
      success: (count) =>
          state.copyWith(unreadCount: count, isRefreshingUnread: false),
      failure: (_) => state.copyWith(isRefreshingUnread: false),
    );
  }

  Future<void> loadNotifications({bool force = false}) async {
    if (state.isLoadingList || (!force && state.hasLoadedList)) return;
    state = state.copyWith(isLoadingList: true, clearListFailure: true);
    final result = await ref
        .read(notificationsRepositoryProvider)
        .getNotifications(
          pageNumber: 1,
          pageSize: state.pageSize,
          unreadOnly: false,
        );
    state = result.when(
      success: (page) => state.copyWith(
        items: page.items,
        pageNumber: page.pageNumber,
        pageSize: page.pageSize,
        totalCount: page.totalCount,
        hasLoadedList: true,
        isLoadingList: false,
        clearListFailure: true,
      ),
      failure: (failure) => state.copyWith(
        hasLoadedList: true,
        isLoadingList: false,
        listFailure: failure,
      ),
    );
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final result = await ref
        .read(notificationsRepositoryProvider)
        .getNotifications(
          pageNumber: state.pageNumber + 1,
          pageSize: state.pageSize,
          unreadOnly: false,
        );
    state = result.when(
      success: (page) => state.copyWith(
        items: _deduplicate([...state.items, ...page.items]),
        pageNumber: page.pageNumber,
        totalCount: page.totalCount,
        isLoadingMore: false,
      ),
      failure: (_) => state.copyWith(isLoadingMore: false),
    );
  }

  Future<Result<void>> markAsRead(String notificationId) async {
    final index = state.items.indexWhere(
      (item) => item.notificationId == notificationId,
    );
    if (index < 0 || state.items[index].isRead) {
      return const Result.success(null);
    }
    final previous = state;
    final updated = [...state.items];
    updated[index] = updated[index].copyWith(
      isRead: true,
      readAtUtc: DateTime.now().toUtc(),
    );
    state = state.copyWith(
      items: updated,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
    final result = await ref
        .read(notificationsRepositoryProvider)
        .markAsRead(notificationId);
    if (result.isFailure) state = previous;
    return result;
  }

  Future<Result<void>> markAllAsRead() async {
    if (state.isMarkingAll || state.unreadCount == 0) {
      return const Result.success(null);
    }
    final previous = state;
    final readAt = DateTime.now().toUtc();
    state = state.copyWith(
      items: state.items
          .map(
            (item) => item.isRead
                ? item
                : item.copyWith(isRead: true, readAtUtc: readAt),
          )
          .toList(growable: false),
      unreadCount: 0,
      isMarkingAll: true,
    );
    final result = await ref
        .read(notificationsRepositoryProvider)
        .markAllAsRead();
    state = result.isSuccess ? state.copyWith(isMarkingAll: false) : previous;
    return result;
  }

  void handleNotificationReceived(AppNotification notification) {
    if (state.items.any(
      (item) => item.notificationId == notification.notificationId,
    )) {
      return;
    }
    state = state.copyWith(
      items: [notification, ...state.items],
      totalCount: state.totalCount + 1,
      unreadCount: notification.isRead
          ? state.unreadCount
          : state.unreadCount + 1,
    );
  }

  Future<void> clear() async {
    await ref.read(notificationRealtimeServiceProvider).disconnect();
    state = const NotificationsState();
  }

  Future<void> _startRealtime() async {
    final realtime = ref.read(notificationRealtimeServiceProvider);
    if (!realtime.isAvailable) return;
    try {
      await realtime.connect(handleNotificationReceived);
    } catch (_) {
      // REST remains authoritative when realtime is unavailable.
    }
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

final notificationsSessionCoordinatorProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authStateControllerProvider, (previous, next) {
    final controller = ref.read(notificationsControllerProvider.notifier);
    if (next.status == AuthStatus.authenticated &&
        previous?.status != AuthStatus.authenticated) {
      unawaited(controller.initialize());
    } else if (next.status == AuthStatus.unauthenticated &&
        previous?.status != AuthStatus.unauthenticated) {
      unawaited(controller.clear());
    }
  }, fireImmediately: true);
});

List<AppNotification> _deduplicate(List<AppNotification> items) {
  final seen = <String>{};
  return items
      .where((item) => seen.add(item.notificationId))
      .toList(growable: false);
}
