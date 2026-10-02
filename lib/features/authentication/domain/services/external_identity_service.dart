import '../entities/external_auth.dart';

abstract class ExternalIdentityService {
  Future<ExternalProviderResult> signIn(ExternalAuthProvider provider);

  Future<void> signOut();
}

class ExternalIdentityException implements Exception {
  const ExternalIdentityException(this.message);
  final String message;
}
