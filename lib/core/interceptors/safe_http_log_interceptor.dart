import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only HTTP diagnostics that recursively mask authentication secrets.
class SafeHttpLogInterceptor extends Interceptor {
  const SafeHttpLogInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('REQUEST: ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('BODY: ${sanitizeHttpValue(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint('RESPONSE: ${response.statusCode}');
    debugPrint('BODY: ${sanitizeHttpValue(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('RESPONSE: ${err.response?.statusCode ?? 'NETWORK_ERROR'}');
    if (err.response?.data != null) {
      debugPrint('BODY: ${sanitizeHttpValue(err.response?.data)}');
    }
    handler.next(err);
  }
}

dynamic sanitizeHttpValue(dynamic value) {
  if (value is Uint8List) return '<binary ${value.length} bytes>';
  if (value is Map) {
    return value.map((key, dynamic nestedValue) {
      final normalizedKey = key.toString().toLowerCase();
      if (_base64Keys.contains(normalizedKey)) {
        return MapEntry(key, '[BASE64_IMAGE_REMOVED]');
      }
      if (_sensitiveKeys.contains(normalizedKey)) {
        return MapEntry(key, '***');
      }
      return MapEntry(key, sanitizeHttpValue(nestedValue));
    });
  }
  if (value is Iterable) {
    return value.map(sanitizeHttpValue).toList(growable: false);
  }
  if (value is FormData) return '<multipart form data>';
  return value;
}

const _sensitiveKeys = {
  'password',
  'newpassword',
  'confirmpassword',
  'code',
  'verificationcode',
  'resetcode',
  'accesstoken',
  'refreshtoken',
  'authorization',
};

const _base64Keys = {'imagebase64', 'base64', 'imagedata'};
