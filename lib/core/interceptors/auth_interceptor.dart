// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/secure_token_storage.dart';

/// Signature for a function that performs the token refresh HTTP call and
/// returns the new access token, or `null` if the refresh failed.
typedef RefreshTokenCall =
    Future<RefreshedTokens?> Function(String refreshToken);

class RefreshedTokens {
  const RefreshedTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

/// Dio interceptor responsible for:
/// 1. Attaching `Authorization: Bearer <accessToken>` to every request.
/// 2. Detecting `401` responses.
/// 3. Refreshing the access token exactly once even if multiple requests
///    fail concurrently (single-flight via a shared [Completer]).
/// 4. Retrying the original request after a successful refresh.
/// 5. Clearing the session and notifying [onSessionExpired] when the
///    refresh itself fails, so the app can redirect to the login screen.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required SecureTokenStorage tokenStorage,
    required RefreshTokenCall refreshTokenCall,
    required this.onSessionExpired,
  }) : _dio = dio,
       _tokenStorage = tokenStorage,
       _refreshTokenCall = refreshTokenCall;

  final Dio _dio;
  final SecureTokenStorage _tokenStorage;
  final RefreshTokenCall _refreshTokenCall;
  final void Function() onSessionExpired;

  /// Shared in-flight refresh operation. When non-null, concurrent 401s
  /// await this instead of triggering a new refresh call.
  Completer<bool>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (!isUnauthorized || alreadyRetried) {
      handler.next(err);
      return;
    }

    final refreshed = await _refreshSession();
    if (!refreshed) {
      onSessionExpired();
      handler.next(err);
      return;
    }

    try {
      final retriedResponse = await _retry(err.requestOptions);
      handler.resolve(retriedResponse);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Ensures only one refresh call is ever in flight at a time. Any
  /// requests that fail with 401 while a refresh is already running await
  /// the same [Completer] instead of issuing duplicate refresh calls.
  Future<bool> _refreshSession() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      return inFlight.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    _performRefresh()
        .then(completer.complete)
        .catchError((_) {
          completer.complete(false);
        })
        .whenComplete(() {
          _refreshCompleter = null;
        });
    return completer.future;
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final refreshedTokens = await _refreshTokenCall(refreshToken);
    if (refreshedTokens == null ||
        refreshedTokens.accessToken.isEmpty ||
        refreshedTokens.refreshToken.isEmpty) {
      await _tokenStorage.clear();
      return false;
    }

    await _tokenStorage.saveTokens(
      accessToken: refreshedTokens.accessToken,
      refreshToken: refreshedTokens.refreshToken,
    );
    return true;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      extra: {...requestOptions.extra, 'retried': true},
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
