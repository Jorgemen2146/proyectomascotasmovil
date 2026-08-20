/// UI-facing representation of a failure, produced by mapping an
/// [AppException] at the repository boundary. Presentation code should only
/// ever handle [AppFailure], never raw exceptions or Dio errors.
sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network error occurred.']);
}

class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {this.statusCode, this.errorCode});

  final int? statusCode;
  final String? errorCode;
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Session expired.']);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});

  final Map<String, List<String>> fieldErrors;
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
