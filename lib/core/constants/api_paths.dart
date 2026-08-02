/// API route path segments shared across features.
///
/// Full URLs are composed by combining [AppConfig] base URLs with these
/// relative paths inside each feature's data source.
class ApiPaths {
  ApiPaths._();

  // Identity service
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/users/me';
}
