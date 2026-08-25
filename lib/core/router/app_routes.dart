/// Centralized route path constants consumed by [AppRouter] and by screens
/// that navigate via `context.go` / `context.push`.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String home = '/home';
  static const String notifications = '/notifications';

  static const String pets = '/pets';
  static const String newPet = '/pets/new';
  static String petDetails(String petId) => '/pets/$petId';
  static String editPet(String petId) => '/pets/$petId/edit';
  static String petPhotos(String petId) => '/pets/$petId/photos';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  static const String genealogy = '/genealogy';
  static String genealogyForPet(String petId) =>
      Uri(path: genealogy, queryParameters: {'petId': petId}).toString();
  static const String genealogyInvitations = '/genealogy/invitations';

  // Placeholder-only route for an upcoming feature.
  static const String matching = '/matching';
  static const String health = '/health';
  static String healthForPet(String petId) =>
      Uri(path: health, queryParameters: {'petId': petId}).toString();
}
