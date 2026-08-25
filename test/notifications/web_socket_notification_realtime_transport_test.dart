import 'dart:async';
import 'dart:io';

import 'package:dogplatform/features/notifications/data/realtime/web_socket_notification_realtime_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('construye ws/wss desde apiBaseUrl sin hosts hardcodeados', () {
    expect(
      WebSocketNotificationRealtimeTransport.buildWebSocketUri(
        'https://api.dogplatform.com',
      ).toString(),
      'wss://api.dogplatform.com/ws/notifications',
    );
    expect(
      WebSocketNotificationRealtimeTransport.buildWebSocketUri(
        'http://10.0.2.2:5101',
      ).toString(),
      'ws://10.0.2.2:5101/ws/notifications',
    );
  });

  test('usa access_token en query y consume notificationReceived', () async {
    final socket = FakeWebSocketConnection();
    Uri? connectedUri;
    final receivedIds = <String>[];
    final transport = WebSocketNotificationRealtimeTransport(
      apiBaseUrl: 'https://api.example.com',
      connector: (uri) async {
        connectedUri = uri;
        return socket;
      },
    );
    addTearDown(transport.disconnect);

    await transport.connect(
      accessTokenProvider: () async => 'secret.token+encoded/value',
      onNotification: (notification) {
        receivedIds.add(notification.notificationId);
      },
      onConnected: () async {},
    );
    socket.add(_notificationEnvelope());
    await _flushEvents();

    expect(connectedUri?.scheme, 'wss');
    expect(connectedUri?.host, 'api.example.com');
    expect(connectedUri?.path, '/ws/notifications');
    expect(
      connectedUri?.queryParameters['access_token'],
      'secret.token+encoded/value',
    );
    expect(receivedIds, ['notification-1']);
  });

  test(
    'ignora evento diferente y JSON invalido sin cerrar el socket',
    () async {
      final socket = FakeWebSocketConnection();
      final receivedIds = <String>[];
      final transport = _transport((_) async => socket);
      addTearDown(transport.disconnect);
      await _connect(transport, receivedIds: receivedIds);

      socket.add('{not-json');
      socket.add('{"event":"other","data":{}}');
      socket.add(_notificationEnvelope(id: 'notification-valid'));
      await _flushEvents();

      expect(receivedIds, ['notification-valid']);
      expect(transport.isConnected, isTrue);
    },
  );

  test('reconecta con backoff, vuelve a pedir token y resincroniza', () async {
    var connectorCalls = 0;
    var tokenCalls = 0;
    var connectedCalls = 0;
    final socket = FakeWebSocketConnection();
    final transport = _transport((_) async {
      connectorCalls++;
      if (connectorCalls == 1) throw const SocketException('offline');
      return socket;
    });
    addTearDown(transport.disconnect);

    await transport.connect(
      accessTokenProvider: () async {
        tokenCalls++;
        return tokenCalls == 1 ? 'old-token' : 'refreshed-token';
      },
      onNotification: (_) {},
      onConnected: () async {
        connectedCalls++;
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(connectorCalls, 2);
    expect(tokenCalls, 2);
    expect(connectedCalls, 1);
    expect(transport.isConnected, isTrue);
  });

  test('connect simultaneos crean una sola conexion', () async {
    var connectorCalls = 0;
    final pending = Completer<NotificationWebSocketConnection>();
    final transport = _transport((_) {
      connectorCalls++;
      return pending.future;
    });
    addTearDown(transport.disconnect);

    final first = _connect(transport);
    final second = _connect(transport);
    pending.complete(FakeWebSocketConnection());
    await Future.wait([first, second]);

    expect(connectorCalls, 1);
  });

  test('disconnect cancela reconexion pendiente', () async {
    var connectorCalls = 0;
    final transport = _transport((_) async {
      connectorCalls++;
      throw const SocketException('offline');
    });

    await _connect(transport);
    await transport.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(connectorCalls, 1);
  });
}

WebSocketNotificationRealtimeTransport _transport(
  NotificationWebSocketConnector connector,
) => WebSocketNotificationRealtimeTransport(
  apiBaseUrl: 'http://gateway.example.com',
  connector: connector,
  reconnectDelays: const [Duration(milliseconds: 5)],
);

Future<void> _connect(
  WebSocketNotificationRealtimeTransport transport, {
  List<String>? receivedIds,
}) => transport.connect(
  accessTokenProvider: () async => 'token',
  onNotification: (notification) {
    receivedIds?.add(notification.notificationId);
  },
  onConnected: () async {},
);

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

String _notificationEnvelope({String id = 'notification-1'}) =>
    '''
{
  "event": "notificationReceived",
  "data": {
    "notificationId": "$id",
    "type": "VaccinationDueSoon",
    "title": "Vacuna proxima",
    "message": "Mensaje",
    "petId": "pet-1",
    "vaccineId": 1,
    "status": "Created",
    "isRead": false,
    "readAtUtc": null,
    "createdAtUtc": "2026-08-25T00:00:00Z",
    "metadataJson": null
  }
}
''';

class FakeWebSocketConnection implements NotificationWebSocketConnection {
  final _controller = StreamController<dynamic>();

  @override
  Stream<dynamic> get messages => _controller.stream;

  void add(dynamic value) => _controller.add(value);

  @override
  Future<void> close() => _controller.close();
}
