import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../interceptors/safe_http_log_interceptor.dart';

/// Builds pre-configured [Dio] instances sharing consistent timeouts and,
/// safe request/response logging in debug builds only.
class DioClientFactory {
  DioClientFactory._();

  static Dio create({required String baseUrl}) {
    final config = AppConfig.instance;
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
        contentType: 'application/json',
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(const SafeHttpLogInterceptor());
    }

    return dio;
  }
}
