/// Centralized route path constants consumed by [AppRouter] and by screens
/// that navigate via `context.go` / `context.push`.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  // Placeholder-only routes for upcoming features (screens not yet built).
  static const String pets = '/pets';
  static const String profile = '/profile';
  static const String genealogy = '/genealogy';
  static const String matching = '/matching';
  static const String health = '/health';
}
