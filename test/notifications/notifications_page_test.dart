import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/theme/app_theme.dart';
import 'package:dogplatform/features/notifications/application/providers.dart';
import 'package:dogplatform/features/notifications/presentation/pages/notifications_page.dart';
import 'package:dogplatform/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:dogplatform/features/notifications/domain/entities/notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes.dart';

void main() {
  for (final testCase in [
    (count: 0, label: null),
    (count: 3, label: '3'),
    (count: 120, label: '99+'),
  ]) {
    testWidgets('badge para count=${testCase.count}', (tester) async {
      final repository = FakeNotificationsRepository()
        ..unreadCount = testCase.count;
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(notificationsControllerProvider.notifier)
          .refreshUnreadCount();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: NotificationBell()),
          ),
        ),
      );

      if (testCase.label == null) {
        expect(find.byKey(const Key('notificationBadge')), findsNothing);
      } else {
        expect(find.text(testCase.label!), findsOneWidget);
      }
    });
  }

  testWidgets('NotificationsPage muestra listado exitoso', (tester) async {
    final repository = FakeNotificationsRepository()
      ..unreadCount = 1
      ..items = [notification()];
    final container = _container(repository);
    addTearDown(container.dispose);
    await container
        .read(notificationsControllerProvider.notifier)
        .refreshUnreadCount();

    await _pumpPage(tester, container);

    expect(find.text('Vacuna próxima'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.byKey(const Key('unreadIndicator')), findsOneWidget);
    expect(find.byKey(const Key('markAllReadButton')), findsOneWidget);
  });

  testWidgets('NotificationsPage muestra estado vacío amigable', (
    tester,
  ) async {
    final container = _container(FakeNotificationsRepository());
    addTearDown(container.dispose);

    await _pumpPage(tester, container);

    expect(find.text('Todo está al día'), findsOneWidget);
    expect(find.textContaining('No tienes notificaciones'), findsOneWidget);
  });

  testWidgets('NotificationsPage oculta error técnico y permite reintentar', (
    tester,
  ) async {
    final repository = FakeNotificationsRepository()
      ..listFailure = const NetworkFailure('DioException SocketException');
    final container = _container(repository);
    addTearDown(container.dispose);

    await _pumpPage(tester, container);

    expect(find.text('No pudimos cargar tus notificaciones'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('DioException'), findsNothing);
  });

  testWidgets('tocar notificación la lee y abre Health con petId real', (
    tester,
  ) async {
    final repository = FakeNotificationsRepository()
      ..unreadCount = 1
      ..items = [notification()];
    final container = _container(repository);
    addTearDown(container.dispose);
    await container
        .read(notificationsControllerProvider.notifier)
        .refreshUnreadCount();
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/health',
          builder: (_, state) => Scaffold(
            body: Text('Health ${state.uri.queryParameters['petId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notification-notification-1')));
    await tester.pumpAndSettle();

    expect(find.text('Health pet-1'), findsOneWidget);
    expect(repository.markReadCalls, 1);
    expect(container.read(notificationsControllerProvider).unreadCount, 0);
  });

  testWidgets('notificación Matching abre detail solo con matchId', (
    tester,
  ) async {
    final repository = FakeNotificationsRepository()
      ..items = [
        AppNotification(
          notificationId: 'matching-1',
          type: 'MatchingRequestAccepted',
          title: '¡Es un match!',
          message: 'Solicitud aceptada',
          status: 'Pending',
          isRead: true,
          createdAtUtc: DateTime.utc(2026, 8, 25),
          metadata: const NotificationMetadata(matchId: 'match-1'),
        ),
      ];
    final container = _container(repository);
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/matching/matches/:matchId',
          builder: (_, state) =>
              Scaffold(body: Text('Match ${state.pathParameters['matchId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notification-matching-1')));
    await tester.pumpAndSettle();
    expect(find.text('Match match-1'), findsOneWidget);
  });

  for (final type in [
    'MatchingBreedingIntentProposed',
    'MatchingBreedingIntentAccepted',
    'MatchingBreedingIntentCancelled',
  ]) {
    testWidgets('$type abre MatchDetail con matchId', (tester) async {
      final repository = FakeNotificationsRepository()
        ..items = [
          AppNotification(
            notificationId: type,
            type: type,
            title: 'Posible camada',
            message: 'Estado actualizado',
            status: 'Pending',
            isRead: true,
            createdAtUtc: DateTime.utc(2026, 8, 25),
            metadata: const NotificationMetadata(
              matchId: 'match-1',
              breedingIntentId: 'intent-1',
            ),
          ),
        ];
      final container = _container(repository);
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/matching/matches/:matchId',
            builder: (_, state) => Scaffold(
              body: Text('Match ${state.pathParameters['matchId']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('notification-$type')));
      await tester.pumpAndSettle();

      expect(find.text('Match match-1'), findsOneWidget);
    });
  }
}

ProviderContainer _container(FakeNotificationsRepository repository) =>
    ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
      ],
    );

Future<void> _pumpPage(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const NotificationsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
