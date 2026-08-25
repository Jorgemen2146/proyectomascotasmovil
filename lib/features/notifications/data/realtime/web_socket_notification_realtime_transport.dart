import 'dart:async';
import 'dart:io';

import '../../domain/repositories/notification_realtime_transport.dart';
import '../dto/notification_dtos.dart';

abstract class NotificationWebSocketConnection {
  Stream<dynamic> get messages;
  Future<void> close();
}

typedef NotificationWebSocketConnector =
    Future<NotificationWebSocketConnection> Function(Uri uri);

class WebSocketNotificationRealtimeTransport
    implements NotificationRealtimeTransport {
  WebSocketNotificationRealtimeTransport({
    required String apiBaseUrl,
    NotificationWebSocketConnector? connector,
    List<Duration>? reconnectDelays,
  }) : uri = buildWebSocketUri(apiBaseUrl),
       _connector = connector ?? _connect,
       _reconnectDelays =
           reconnectDelays ??
           const [
             Duration(seconds: 1),
             Duration(seconds: 2),
             Duration(seconds: 5),
             Duration(seconds: 10),
             Duration(seconds: 30),
           ];

  final Uri uri;
  final NotificationWebSocketConnector _connector;
  final List<Duration> _reconnectDelays;

  NotificationWebSocketConnection? _connection;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  NotificationAccessTokenProvider? _accessTokenProvider;
  NotificationReceivedCallback? _onNotification;
  NotificationConnectedCallback? _onConnected;
  bool _shouldConnect = false;
  bool _isConnecting = false;
  int _reconnectAttempt = 0;
  int _generation = 0;

  @override
  bool get isConnected => _connection != null;

  @override
  Future<void> connect({
    required NotificationAccessTokenProvider accessTokenProvider,
    required NotificationReceivedCallback onNotification,
    required NotificationConnectedCallback onConnected,
  }) async {
    _accessTokenProvider = accessTokenProvider;
    _onNotification = onNotification;
    _onConnected = onConnected;
    _shouldConnect = true;
    if (isConnected || _isConnecting || _reconnectTimer != null) return;
    await _attemptConnection(_generation);
  }

  @override
  Future<void> disconnect() async {
    _shouldConnect = false;
    _generation++;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final subscription = _subscription;
    final connection = _connection;
    _subscription = null;
    _connection = null;
    await subscription?.cancel();
    await connection?.close();
  }

  Future<void> _attemptConnection(int generation) async {
    if (!_shouldConnect || generation != _generation || _isConnecting) return;
    _isConnecting = true;
    try {
      final token = await _accessTokenProvider?.call();
      if (!_shouldConnect || generation != _generation) return;
      if (token == null || token.isEmpty) {
        throw StateError('No authenticated session is available.');
      }
      final authenticatedUri = uri.replace(
        queryParameters: {...uri.queryParameters, 'access_token': token},
      );
      final connection = await _connector(authenticatedUri);
      if (!_shouldConnect || generation != _generation) {
        await connection.close();
        return;
      }
      _connection = connection;
      _reconnectAttempt = 0;
      _subscription = connection.messages.listen(
        _handleMessage,
        onError: (_) => _handleConnectionEnded(connection, generation),
        onDone: () => _handleConnectionEnded(connection, generation),
        cancelOnError: true,
      );
      try {
        await _onConnected?.call();
      } catch (_) {
        // A REST resync failure must not tear down a healthy socket.
      }
    } catch (_) {
      _scheduleReconnect(generation);
    } finally {
      _isConnecting = false;
    }
  }

  void _handleMessage(dynamic rawMessage) {
    if (rawMessage is! String) return;
    final notification = NotificationRealtimeEnvelopeDto.tryParse(rawMessage);
    if (notification == null) return;
    try {
      _onNotification?.call(notification);
    } catch (_) {
      // A consumer error must not cancel the receive loop.
    }
  }

  void _handleConnectionEnded(
    NotificationWebSocketConnection connection,
    int generation,
  ) {
    if (!identical(_connection, connection)) return;
    _connection = null;
    _subscription = null;
    unawaited(connection.close());
    _scheduleReconnect(generation);
  }

  void _scheduleReconnect(int generation) {
    if (!_shouldConnect ||
        generation != _generation ||
        _reconnectTimer != null) {
      return;
    }
    final index = _reconnectAttempt.clamp(0, _reconnectDelays.length - 1);
    final delay = _reconnectDelays[index];
    if (_reconnectAttempt < _reconnectDelays.length - 1) {
      _reconnectAttempt++;
    }
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      unawaited(_attemptConnection(generation));
    });
  }

  static Uri buildWebSocketUri(String apiBaseUrl) {
    final base = Uri.parse(apiBaseUrl);
    final scheme = switch (base.scheme.toLowerCase()) {
      'https' => 'wss',
      'http' => 'ws',
      _ => throw ArgumentError.value(apiBaseUrl, 'apiBaseUrl'),
    };
    final basePath = base.path.replaceFirst(RegExp(r'/+$'), '');
    return base.replace(
      scheme: scheme,
      path: '$basePath/ws/notifications',
      query: null,
      fragment: null,
    );
  }

  static Future<NotificationWebSocketConnection> _connect(Uri uri) async =>
      _IoNotificationWebSocketConnection(
        await WebSocket.connect(uri.toString()),
      );
}

class _IoNotificationWebSocketConnection
    implements NotificationWebSocketConnection {
  const _IoNotificationWebSocketConnection(this._socket);

  final WebSocket _socket;

  @override
  Stream<dynamic> get messages => _socket;

  @override
  Future<void> close() async {
    await _socket.close(WebSocketStatus.normalClosure);
  }
}
