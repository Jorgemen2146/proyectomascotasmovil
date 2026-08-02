/// Base class for all typed exceptions thrown by the data layer.
///
/// These are caught by repositories and mapped into [AppFailure]s so that
/// the domain/application layers never depend on Dio or any transport
/// specific exception type.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Network unreachable, timeout, or no internet connection.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error occurred.']);
}

/// Server responded with a 4xx/5xx status code.
class ServerException extends AppException {
  const ServerException(
    super.message, {
    this.statusCode,
  });

  final int? statusCode;
}

/// 401 Unauthorized after a failed (or absent) token refresh.
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired.']);
}

/// Request payload failed validation on the server (422/400 with field errors).
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.fieldErrors = const {},
  });

  final Map<String, List<String>> fieldErrors;
}

/// Any other unexpected failure (parsing errors, unknown states, etc).
class UnknownException extends AppException {
  const UnknownException([super.message = 'An unexpected error occurred.']);
}
