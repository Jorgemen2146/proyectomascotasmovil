import 'dart:convert';

/// Transport-neutral event emitted by the authenticated realtime channel.
class RealtimeEvent {
  const RealtimeEvent({required this.name, required this.data});

  final String name;
  final Map<String, dynamic> data;

  static RealtimeEvent? tryParse(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      final name = decoded['event'];
      final data = decoded['data'];
      if (name is! String || name.isEmpty || data is! Map<String, dynamic>) {
        return null;
      }
      return RealtimeEvent(name: name, data: data);
    } on Object {
      return null;
    }
  }
}

/// Shared realtime abstraction. Feature code never depends on WebSocket APIs.
/// A future SignalR implementation only needs to satisfy this interface.
abstract class RealtimeClient {
  Stream<RealtimeEvent> get events;
  Stream<void> get connections;
}
