/// API route path segments shared across features.
///
/// Full URLs are composed by combining [AppConfig] base URLs with these
/// relative paths inside each feature's data source.
class ApiPaths {
  ApiPaths._();

  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String verifyEmail = '/api/v1/auth/verify-email';
  static const String resendVerification = '/api/v1/auth/resend-verification';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';
  static const String me = '/api/v1/auth/me';
}
