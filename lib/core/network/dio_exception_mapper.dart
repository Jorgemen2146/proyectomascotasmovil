import 'package:dio/dio.dart';

import '../exceptions/app_exceptions.dart';

/// Translates a [DioException] into a typed [AppException] so that
/// repositories never leak Dio-specific types past the data layer.
AppException mapDioExceptionToAppException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      break;
    default:
      break;
  }

  final statusCode = error.response?.statusCode;
  final data = error.response?.data;

  if (statusCode == 401) {
    return UnauthorizedException(
      _extractMessage(data) ?? 'Session expired.',
      _extractErrorCode(data),
    );
  }

  if (statusCode == 400 || statusCode == 422) {
    return ValidationException(
      _extractMessage(data) ?? 'Validation error.',
      fieldErrors: _extractFieldErrors(data),
    );
  }

  if (statusCode != null) {
    return ServerException(
      _extractMessage(data) ?? 'Request failed with status $statusCode.',
      statusCode: statusCode,
      errorCode: _extractErrorCode(data),
    );
  }

  return const UnknownException();
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final fieldErrors = _extractFieldErrors(data);
    for (final messages in fieldErrors.values) {
      if (messages.isNotEmpty && messages.first.trim().isNotEmpty) {
        return messages.first;
      }
    }
    final message = data['description'] ?? data['message'] ?? data['title'];
    if (message != null) return message.toString();
  }
  return null;
}

String? _extractErrorCode(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data['error']?.toString();
  }
  return null;
}

Map<String, List<String>> _extractFieldErrors(dynamic data) {
  if (data is Map<String, dynamic> && data['errors'] is Map) {
    final rawErrors = (data['errors'] as Map).cast<String, dynamic>();
    return rawErrors.map(
      (key, value) => MapEntry(
        key,
        (value is List)
            ? value.map((e) => e.toString()).toList()
            : <String>[value.toString()],
      ),
    );
  }
  return const {};
}
