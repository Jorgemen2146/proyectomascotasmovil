import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/dio_exception_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remoteDataSource);

  final NotificationsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<NotificationPageResult>> getNotifications({
    required int pageNumber,
    required int pageSize,
    required bool unreadOnly,
  }) => _run(() async {
    final dto = await _remoteDataSource.getNotifications(
      pageNumber: pageNumber,
      pageSize: pageSize,
      unreadOnly: unreadOnly,
    );
    return dto.toDomain();
  });

  @override
  Future<Result<int>> getUnreadCount() =>
      _run(() async => (await _remoteDataSource.getUnreadCount()).count);

  @override
  Future<Result<void>> markAsRead(String notificationId) =>
      _run(() => _remoteDataSource.markAsRead(notificationId));

  @override
  Future<Result<void>> markAllAsRead() => _run(_remoteDataSource.markAllAsRead);

  Future<Result<T>> _run<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } on DioException catch (error) {
      return Result.failure(
        mapExceptionToFailure(mapDioExceptionToAppException(error)),
      );
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }
}
