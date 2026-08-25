import 'package:dio/dio.dart';
import 'package:dogplatform/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa paths, query params y verbos exactos de Postman', () async {
    final recorder = _RecordingDio();
    final source = NotificationsRemoteDataSource(dio: recorder.dio);

    await source.getNotifications(
      pageNumber: 2,
      pageSize: 20,
      unreadOnly: true,
    );
    await source.getUnreadCount();
    await source.markAsRead('notification-1');
    await source.markAllAsRead();

    expect(recorder.requests[0].path, '/api/v1/notifications');
    expect(recorder.requests[0].queryParameters, {
      'pageNumber': 2,
      'pageSize': 20,
      'unreadOnly': true,
    });
    expect(recorder.requests[1].path, '/api/v1/notifications/unread-count');
    expect(recorder.requests[2].method, 'PUT');
    expect(
      recorder.requests[2].path,
      '/api/v1/notifications/notification-1/read',
    );
    expect(recorder.requests[3].method, 'PUT');
    expect(recorder.requests[3].path, '/api/v1/notifications/read-all');
  });
}

class _RecordingDio {
  _RecordingDio() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          final data = switch (request.path) {
            '/api/v1/notifications' => {
              'items': <dynamic>[],
              'pageNumber': 2,
              'pageSize': 20,
              'totalCount': 0,
            },
            '/api/v1/notifications/unread-count' => {'count': 0},
            _ => null,
          };
          handler.resolve(
            Response<dynamic>(
              requestOptions: request,
              statusCode: request.method == 'PUT' ? 204 : 200,
              data: data,
            ),
          );
        },
      ),
    );
  }

  final Dio dio = Dio();
  final List<RequestOptions> requests = [];
}
