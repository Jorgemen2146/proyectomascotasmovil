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
  static const String mePhoto = '/api/v1/auth/me/photo';

  static const String pets = '/api/v1/pets';
  static const String myPets = '/api/v1/pets/mine';
  static const String species = '/api/v1/species';

  static String pet(String petId) => '$pets/$petId';
  static String breeds(int speciesId) => '$species/$speciesId/breeds';
  static String petPhotos(String petId) => '${pet(petId)}/photos';
  static String petPhoto(String petId, String photoId) =>
      '${petPhotos(petId)}/$photoId';
  static String mainPetPhoto(String petId, String photoId) =>
      '${petPhoto(petId, photoId)}/main';

  static String genealogyParents(String petId) =>
      '/api/v1/genealogy/pets/$petId/parents';
  static String genealogyTree(String petId) =>
      '/api/v1/genealogy/pets/$petId/tree';
  static String genealogyRelationship(String id) =>
      '/api/v1/genealogy/relationships/$id';
  static const genealogyInvitations = '/api/v1/genealogy/invitations';
  static const genealogyMyInvitations = '$genealogyInvitations/mine';
  static String genealogyInvitation(String token) =>
      '$genealogyInvitations/$token';
  static String genealogyAcceptInvitation(String token) =>
      '${genealogyInvitation(token)}/accept';
  static String genealogyRejectInvitation(String token) =>
      '${genealogyInvitation(token)}/reject';
  static String genealogyCancelInvitation(String id) =>
      '$genealogyInvitations/$id/cancel';
}
