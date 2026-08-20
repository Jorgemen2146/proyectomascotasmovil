/// Centralized route path constants consumed by [AppRouter] and by screens
/// that navigate via `context.go` / `context.push`.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String home = '/home';

  static const String pets = '/pets';
  static const String newPet = '/pets/new';
  static String petDetails(String petId) => '/pets/$petId';
  static String editPet(String petId) => '/pets/$petId/edit';
  static String petPhotos(String petId) => '/pets/$petId/photos';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // Placeholder-only routes for upcoming features.
  static const String genealogy = '/genealogy';
  static const String matching = '/matching';
  static const String health = '/health';
}
