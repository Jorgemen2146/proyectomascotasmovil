import '../../../../core/result/result.dart';
import '../entities/notification.dart';

abstract class NotificationsRepository {
  Future<Result<NotificationPageResult>> getNotifications({
    required int pageNumber,
    required int pageSize,
    required bool unreadOnly,
  });

  Future<Result<int>> getUnreadCount();
  Future<Result<void>> markAsRead(String notificationId);
  Future<Result<void>> markAllAsRead();
}
