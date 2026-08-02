import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Builds pre-configured [Dio] instances sharing consistent timeouts and,
/// in non-production environments, verbose request/response logging.
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

    if (!config.isProd) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }
}
