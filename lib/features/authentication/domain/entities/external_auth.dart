import 'user.dart';

enum ExternalAuthProvider { google, apple, facebook }

extension ExternalAuthProviderX on ExternalAuthProvider {
  String get label => switch (this) {
    ExternalAuthProvider.google => 'Google',
    ExternalAuthProvider.apple => 'Apple',
    ExternalAuthProvider.facebook => 'Facebook',
  };
}

class ExternalProviderCredential {
  const ExternalProviderCredential({
    required this.provider,
    required this.credential,
    this.nonce,
  });

  final ExternalAuthProvider provider;
  final String credential;
  final String? nonce;
}

sealed class ExternalProviderResult {
  const ExternalProviderResult();
}

class ExternalProviderSuccess extends ExternalProviderResult {
  const ExternalProviderSuccess(this.credential);
  final ExternalProviderCredential credential;
}

class ExternalProviderCancelled extends ExternalProviderResult {
  const ExternalProviderCancelled();
}

sealed class ExternalAuthResult {
  const ExternalAuthResult();
}

class ExternalAuthAuthenticated extends ExternalAuthResult {
  const ExternalAuthAuthenticated(this.user);
  final User user;
}

class ExternalRegistrationRequired extends ExternalAuthResult {
  const ExternalRegistrationRequired({
    required this.registrationToken,
    this.email,
    this.firstName,
    this.lastName,
    this.missingFields = const {'email', 'firstName', 'lastName'},
  });

  final String registrationToken;
  final String? email;
  final String? firstName;
  final String? lastName;
  final Set<String> missingFields;
}
