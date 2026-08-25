import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/notifications/application/providers.dart';
import 'package:dogplatform/features/notifications/domain/entities/notification.dart';
import 'package:dogplatform/features/notifications/domain/repositories/notifications_repository.dart';

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

class ThrowingRealtimeService implements NotificationRealtimeService {
  int disconnectCalls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<void> connect(
    void Function(AppNotification notification) onNotification,
  ) => throw StateError('hub unavailable');

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
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
