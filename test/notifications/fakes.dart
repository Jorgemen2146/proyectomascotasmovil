import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/notifications/domain/entities/notification.dart';
import 'package:dogplatform/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:dogplatform/features/notifications/domain/repositories/notification_realtime_transport.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  int unreadCount = 0;
  List<AppNotification> items = [];
  AppFailure? listFailure;
  AppFailure? mutationFailure;
  int listCalls = 0;
  int unreadCalls = 0;
  int markReadCalls = 0;
  int markAllCalls = 0;

  @override
  Future<Result<NotificationPageResult>> getNotifications({
    required int pageNumber,
    required int pageSize,
    required bool unreadOnly,
  }) async {
    listCalls++;
    final failure = listFailure;
    if (failure != null) return Result.failure(failure);
    return Result.success(
      NotificationPageResult(
        items: items,
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalCount: items.length,
      ),
    );
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    unreadCalls++;
    return Result.success(unreadCount);
  }

  @override
  Future<Result<void>> markAllAsRead() async {
    markAllCalls++;
    final failure = mutationFailure;
    return failure == null
        ? const Result.success(null)
        : Result.failure(failure);
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    markReadCalls++;
    final failure = mutationFailure;
    return failure == null
        ? const Result.success(null)
        : Result.failure(failure);
  }
}

class FakeRealtimeTransport implements NotificationRealtimeTransport {
  int connectCalls = 0;
  int disconnectCalls = 0;
  bool throwOnConnect = false;
  NotificationReceivedCallback? onNotification;
  NotificationConnectedCallback? onConnected;

  @override
  bool isConnected = false;

  @override
  Future<void> connect({
    required NotificationAccessTokenProvider accessTokenProvider,
    required NotificationReceivedCallback onNotification,
    required NotificationConnectedCallback onConnected,
  }) async {
    connectCalls++;
    this.onNotification = onNotification;
    this.onConnected = onConnected;
    await accessTokenProvider();
    if (throwOnConnect) throw StateError('socket unavailable');
    isConnected = true;
  }

  void emit(AppNotification value) => onNotification?.call(value);

  Future<void> simulateConnected() async => onConnected?.call();

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    isConnected = false;
  }
}

class ThrowingRealtimeTransport extends FakeRealtimeTransport {
  ThrowingRealtimeTransport() {
    throwOnConnect = true;
  }
}

AppNotification notification({
  String id = 'notification-1',
  String type = 'VaccinationDueSoon',
  bool isRead = false,
  String? petId = 'pet-1',
}) => AppNotification(
  notificationId: id,
  type: type,
  title: 'Vacuna próxima',
  message: 'La vacuna de Rabia de Luna se aproxima.',
  petId: petId,
  vaccineId: 1,
  status: 'Pending',
  isRead: isRead,
  createdAtUtc: DateTime.utc(2026, 8, 23, 10),
  metadata: const NotificationMetadata(petName: 'Luna', vaccineName: 'Rabia'),
);
