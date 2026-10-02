/// Centralized route path constants consumed by [AppRouter] and by screens
/// that navigate via `context.go` / `context.push`.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String completeExternalRegistration =
      '/complete-external-registration';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String verifyResetCode = '/verify-reset-code';
  static const String resetPassword = '/reset-password';
  static const String passwordResetSuccess = '/password-reset-success';
  static const String home = '/home';
  static const String notifications = '/notifications';
  static const String legalTerms = '/legal/terms';
  static const String legalPrivacy = '/legal/privacy';
  static const String legalUpdate = '/legal/update';
  static const String legalHistory = '/legal/history';

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

  static const String matching = '/matching';
  static String matchingForPet(String petId) =>
      Uri(path: matching, queryParameters: {'petId': petId}).toString();
  static const String matchingRequests = '/matching/requests';
  static const String matchingMatches = '/matching/matches';
  static String matchingCandidate(String sourcePetId, String candidatePetId) =>
      Uri(
        path: '/matching/pets/$candidatePetId',
        queryParameters: {'sourcePetId': sourcePetId},
      ).toString();
  static String matchingMatch(String matchId) => '/matching/matches/$matchId';
  static const String health = '/health';
  static String healthForPet(String petId) =>
      Uri(path: health, queryParameters: {'petId': petId}).toString();
}
