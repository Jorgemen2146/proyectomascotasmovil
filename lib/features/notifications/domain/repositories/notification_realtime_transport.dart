import '../entities/notification.dart';

typedef NotificationAccessTokenProvider = Future<String?> Function();
typedef NotificationReceivedCallback =
    void Function(AppNotification notification);
typedef NotificationConnectedCallback = Future<void> Function();

/// Best-effort realtime channel. REST remains the persistent source of truth.
abstract class NotificationRealtimeTransport {
  bool get isConnected;

  Future<void> connect({
    required NotificationAccessTokenProvider accessTokenProvider,
    required NotificationReceivedCallback onNotification,
    required NotificationConnectedCallback onConnected,
  });

  Future<void> disconnect();
}
