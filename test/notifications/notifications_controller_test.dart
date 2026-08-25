import 'package:dogplatform/features/notifications/application/providers.dart';
import 'package:dogplatform/features/authentication/application/auth_state.dart';
import 'package:dogplatform/features/authentication/application/auth_state_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  test('no conecta sin sesion y conecta al autenticarse', () async {
    final repository = FakeNotificationsRepository();
    final realtime = FakeRealtimeTransport();
    final auth = StubAuthStateController();
    final container = _container(
      repository,
      realtime: realtime,
      authController: auth,
    );
    addTearDown(container.dispose);

    container.read(notificationsSessionCoordinatorProvider);
    await _flushEvents();
    expect(realtime.connectCalls, 0);

    auth.setStatus(AuthStatus.authenticated);
    await _flushEvents();
    expect(realtime.connectCalls, 1);
  });

  test('logout desconecta y limpia estado global', () async {
    final repository = FakeNotificationsRepository();
    final realtime = FakeRealtimeTransport();
    final auth = StubAuthStateController(AuthStatus.authenticated);
    final container = _container(
      repository,
      realtime: realtime,
      authController: auth,
    );
    addTearDown(container.dispose);

    container.read(notificationsSessionCoordinatorProvider);
    await _flushEvents();
    realtime.emit(notification());
    expect(container.read(notificationsControllerProvider).unreadCount, 1);

    auth.setStatus(AuthStatus.unauthenticated);
    await _flushEvents();

    expect(realtime.disconnectCalls, 1);
    expect(container.read(notificationsControllerProvider).items, isEmpty);
    expect(container.read(notificationsControllerProvider).unreadCount, 0);
  });

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
    final realtime = FakeRealtimeTransport();
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

  test('notificationId existente se actualiza sin duplicar', () {
    final container = _container(FakeNotificationsRepository());
    addTearDown(container.dispose);
    final controller = container.read(notificationsControllerProvider.notifier);
    controller.handleNotificationReceived(notification(isRead: true));

    controller.handleNotificationReceived(notification(isRead: false));

    final state = container.read(notificationsControllerProvider);
    expect(state.items, hasLength(1));
    expect(state.items.single.isRead, isFalse);
    expect(state.unreadCount, 1);
  });

  test(
    'initialize conecta realtime y el evento actualiza badge/lista',
    () async {
      final repository = FakeNotificationsRepository();
      final realtime = FakeRealtimeTransport();
      final container = _container(repository, realtime: realtime);
      addTearDown(container.dispose);

      await container
          .read(notificationsControllerProvider.notifier)
          .initialize();
      realtime.emit(notification());

      final state = container.read(notificationsControllerProvider);
      expect(realtime.connectCalls, 1);
      expect(state.items.single.notificationId, 'notification-1');
      expect(state.unreadCount, 1);
    },
  );

  test('foreground resincroniza unread y lista y asegura conexion', () async {
    final repository = FakeNotificationsRepository()
      ..unreadCount = 2
      ..items = [notification(id: 'persisted')];
    final realtime = FakeRealtimeTransport();
    final container = _container(repository, realtime: realtime);
    addTearDown(container.dispose);
    final controller = container.read(notificationsControllerProvider.notifier);
    await controller.loadNotifications();
    repository.listCalls = 0;
    repository.unreadCalls = 0;

    await controller.resumeFromBackground();

    final state = container.read(notificationsControllerProvider);
    expect(repository.unreadCalls, greaterThanOrEqualTo(1));
    expect(repository.listCalls, 1);
    expect(realtime.connectCalls, 1);
    expect(state.unreadCount, 2);
    expect(state.items.single.notificationId, 'persisted');
  });

  test('conexion exitosa resincroniza unread-count', () async {
    final repository = FakeNotificationsRepository()..unreadCount = 7;
    final realtime = FakeRealtimeTransport();
    final container = _container(repository, realtime: realtime);
    addTearDown(container.dispose);

    await container.read(notificationsControllerProvider.notifier).initialize();
    repository.unreadCalls = 0;
    await realtime.simulateConnected();

    expect(repository.unreadCalls, 1);
    expect(container.read(notificationsControllerProvider).unreadCount, 7);
  });

  test('fallo realtime no rompe inicialización REST', () async {
    final repository = FakeNotificationsRepository()..unreadCount = 4;
    final container = _container(
      repository,
      realtime: ThrowingRealtimeTransport(),
    );
    addTearDown(container.dispose);

    await container.read(notificationsControllerProvider.notifier).initialize();

    expect(container.read(notificationsControllerProvider).unreadCount, 4);
    expect(repository.unreadCalls, 1);
  });
}

ProviderContainer _container(
  FakeNotificationsRepository repository, {
  FakeRealtimeTransport? realtime,
  StubAuthStateController? authController,
}) => ProviderContainer(
  overrides: [
    notificationsRepositoryProvider.overrideWithValue(repository),
    notificationAccessTokenProvider.overrideWithValue(() async => 'token'),
    if (realtime != null)
      notificationRealtimeTransportProvider.overrideWithValue(realtime),
    if (authController != null)
      authStateControllerProvider.overrideWith(() => authController),
  ],
);

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class StubAuthStateController extends AuthStateController {
  StubAuthStateController([this.initialStatus = AuthStatus.unauthenticated]);

  final AuthStatus initialStatus;

  @override
  AuthState build() => AuthState(status: initialStatus);

  void setStatus(AuthStatus status) {
    state = AuthState(status: status);
  }
}
