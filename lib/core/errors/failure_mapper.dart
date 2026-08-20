import '../exceptions/app_exceptions.dart';
import 'app_failure.dart';

/// Maps low-level [AppException]s (thrown by data sources) into
/// presentation-friendly [AppFailure]s. Keeps repositories free of
/// duplicated try/catch-to-failure boilerplate.
AppFailure mapExceptionToFailure(Object error) {
  if (error is NetworkException) {
    return NetworkFailure(error.message);
  }
  if (error is UnauthorizedException) {
    return UnauthorizedFailure(error.message, error.errorCode);
  }
  if (error is ValidationException) {
    return ValidationFailure(error.message, fieldErrors: error.fieldErrors);
  }
  if (error is ServerException) {
    return ServerFailure(
      error.message,
      statusCode: error.statusCode,
      errorCode: error.errorCode,
    );
  }
  if (error is AppException) {
    return UnknownFailure(error.message);
  }
  return const UnknownFailure();
}
