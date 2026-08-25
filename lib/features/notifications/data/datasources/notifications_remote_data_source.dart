import 'package:dio/dio.dart';

import '../dto/notification_dtos.dart';

class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource({required Dio dio}) : this._internal(dio);

  const NotificationsRemoteDataSource._internal(this._dio);

  final Dio _dio;

  Future<NotificationPageDto> getNotifications({
    required int pageNumber,
    required int pageSize,
    required bool unreadOnly,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/notifications',
      queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        'unreadOnly': unreadOnly,
      },
    );
    return NotificationPageDto.fromJson(response.data!);
  }

  Future<UnreadCountDto> getUnreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/notifications/unread-count',
    );
    return UnreadCountDto.fromJson(response.data!);
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.put<void>('/api/v1/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.put<void>('/api/v1/notifications/read-all');
  }
}
