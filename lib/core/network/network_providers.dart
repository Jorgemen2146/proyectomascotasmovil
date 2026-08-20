import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../constants/api_paths.dart';
import '../interceptors/auth_interceptor.dart';
import '../services/session_events.dart';
import '../storage/secure_token_storage.dart';
import 'dio_client_factory.dart';

/// Provides the singleton [SecureTokenStorage] used across the app.
final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

/// Raw Gateway client with NO auth interceptor.
///
/// Used exclusively for endpoints that must never trigger a token refresh
/// themselves: login, register and the refresh call itself. Attaching the
/// [AuthInterceptor] here would risk infinite refresh loops.
final gatewayRawDioProvider = Provider<Dio>((ref) {
  return DioClientFactory.create(baseUrl: AppConfig.instance.apiBaseUrl);
});

/// Authenticated Gateway client. Automatically attaches
/// the bearer access token, refreshes it exactly once on 401 (single-flight),
/// retries the failed request, and signals [SessionEvents] on refresh failure.
final gatewayDioProvider = Provider<Dio>((ref) {
  final dio = DioClientFactory.create(baseUrl: AppConfig.instance.apiBaseUrl);
  final tokenStorage = ref.read(secureTokenStorageProvider);
  final rawDio = ref.read(gatewayRawDioProvider);

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokenStorage: tokenStorage,
      refreshTokenCall: (refreshToken) => _refreshTokens(rawDio, refreshToken),
      onSessionExpired: SessionEvents.notifySessionExpired,
    ),
  );

  return dio;
});

/// Calls Identity's Gateway refresh route using the raw client and extracts
/// the rotated token pair.
Future<RefreshedTokens?> _refreshTokens(Dio rawDio, String refreshToken) async {
  try {
    final response = await rawDio.post<Map<String, dynamic>>(
      ApiPaths.refresh,
      data: {'refreshToken': refreshToken},
    );
    final data = response.data;
    final accessToken = data?['accessToken'] as String?;
    final newRefreshToken = data?['refreshToken'] as String?;
    if (accessToken == null || newRefreshToken == null) return null;
    return RefreshedTokens(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
    );
  } on DioException {
    return null;
  }
}
