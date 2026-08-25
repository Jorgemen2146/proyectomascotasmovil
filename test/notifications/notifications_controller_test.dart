import 'package:dogplatform/features/notifications/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  test('unreadCount = 0 permanece sin pendientes', () async {
    final repository = FakeNotificationsRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    await container
        .read(notificationsControllerProvider.notifier)
        .refreshUnreadCount();

    expect(container.read(notificationsControllerProvider).unreadCount, 0);
  });

  test('unreadCount > 0 actualiza la fuente global', () async {
    final repository = FakeNotificationsRepository()..unreadCount = 3;
    final container = _container(repository);
    addTearDown(container.dispose);

    await container
        .read(notificationsControllerProvider.notifier)
        .refreshUnreadCount();

    expect(container.read(notificationsControllerProvider).unreadCount, 3);
  });

  test('listado exitoso y marcar una actualizan item y contador', () async {
    final repository = FakeNotificationsRepository()
      ..unreadCount = 1
      ..items = [notification()];
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(notificationsControllerProvider.notifier);

    await controller.refreshUnreadCount();
    await controller.loadNotifications();
    final result = await controller.markAsRead('notification-1');

    final state = container.read(notificationsControllerProvider);
    expect(result.isSuccess, isTrue);
    expect(state.items.single.isRead, isTrue);
    expect(state.unreadCount, 0);
    expect(repository.markReadCalls, 1);
  });

  test('read-all usa una llamada y pone lista/count en leído', () async {
    final repository = FakeNotificationsRepository()
      ..unreadCount = 2
      ..items = [notification(), notification(id: 'notification-2')];
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(notificationsControllerProvider.notifier);

    await controller.refreshUnreadCount();
    await controller.loadNotifications();
    await controller.markAllAsRead();

    final state = container.read(notificationsControllerProvider);
    expect(state.items.every((item) => item.isRead), isTrue);
    expect(state.unreadCount, 0);
    expect(repository.markAllCalls, 1);
    expect(repository.markReadCalls, 0);
  });

  test('logout/clear borra lista, count y desconecta realtime', () async {
    final repository = FakeNotificationsRepository()
      ..unreadCount = 1
      ..items = [notification()];
    final realtime = ThrowingRealtimeService();
    final container = _container(repository, realtime: realtime);
    addTearDown(container.dispose);
    final controller = container.read(notificationsControllerProvider.notifier);
    await controller.refreshUnreadCount();
    await controller.loadNotifications();

    await controller.clear();

    final state = container.read(notificationsControllerProvider);
    expect(state.items, isEmpty);
    expect(state.unreadCount, 0);
    expect(realtime.disconnectCalls, 1);
  });

  test('notificationReceived incrementa una vez y evita duplicados', () {
    final container = _container(FakeNotificationsRepository());
    addTearDown(container.dispose);
    final controller = container.read(notificationsControllerProvider.notifier);
    final received = notification();

    controller.handleNotificationReceived(received);
    controller.handleNotificationReceived(received);

    final state = container.read(notificationsControllerProvider);
    expect(state.items, hasLength(1));
    expect(state.unreadCount, 1);
  });

  test('fallo realtime no rompe inicialización REST', () async {
    final repository = FakeNotificationsRepository()..unreadCount = 4;
    final container = _container(
      repository,
      realtime: ThrowingRealtimeService(),
    );
    addTearDown(container.dispose);

    await container.read(notificationsControllerProvider.notifier).initialize();

    expect(container.read(notificationsControllerProvider).unreadCount, 4);
    expect(repository.unreadCalls, 1);
  });
}

ProviderContainer _container(
  FakeNotificationsRepository repository, {
  NotificationRealtimeService? realtime,
}) => ProviderContainer(
  overrides: [
    notificationsRepositoryProvider.overrideWithValue(repository),
    if (realtime != null)
      notificationRealtimeServiceProvider.overrideWithValue(realtime),
  ],
);
