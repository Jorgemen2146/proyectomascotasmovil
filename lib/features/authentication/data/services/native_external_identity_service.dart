import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/entities/external_auth.dart';
import '../../domain/services/external_identity_service.dart';

class NativeExternalIdentityService implements ExternalIdentityService {
  NativeExternalIdentityService({GoogleSignIn? google, FacebookAuth? facebook})
    : _google = google ?? GoogleSignIn.instance,
      _facebook = facebook ?? FacebookAuth.instance;

  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const _googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const _appleServiceId = String.fromEnvironment('APPLE_SERVICE_ID');
  static const _appleRedirectUri = String.fromEnvironment('APPLE_REDIRECT_URI');

  final GoogleSignIn _google;
  final FacebookAuth _facebook;
  bool _googleInitialized = false;

  @override
  Future<ExternalProviderResult> signIn(ExternalAuthProvider provider) async {
    try {
      return switch (provider) {
        ExternalAuthProvider.google => await _signInGoogle(),
        ExternalAuthProvider.facebook => await _signInFacebook(),
        ExternalAuthProvider.apple => await _signInApple(),
      };
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const ExternalProviderCancelled();
      }
      throw ExternalIdentityException(
        'No se pudo iniciar sesión con Google. Revisa su configuración.',
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return const ExternalProviderCancelled();
      }
      throw const ExternalIdentityException(
        'No se pudo iniciar sesión con Apple. Inténtalo nuevamente.',
      );
    } on ExternalIdentityException {
      rethrow;
    } catch (_) {
      throw ExternalIdentityException(
        'No se pudo conectar con ${provider.label}. Inténtalo nuevamente.',
      );
    }
  }

  Future<ExternalProviderResult> _signInGoogle() async {
    if (!_googleInitialized) {
      await _google.initialize(
        clientId: Platform.isIOS && _googleIosClientId.isNotEmpty
            ? _googleIosClientId
            : null,
        serverClientId: _googleServerClientId.isEmpty
            ? null
            : _googleServerClientId,
      );
      _googleInitialized = true;
    }
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const ExternalIdentityException(
        'Google no entregó una credencial válida para PetLife.',
      );
    }
    return ExternalProviderSuccess(
      ExternalProviderCredential(
        provider: ExternalAuthProvider.google,
        credential: idToken,
      ),
    );
  }

  Future<ExternalProviderResult> _signInFacebook() async {
    final result = await _facebook.login(
      permissions: const ['email', 'public_profile'],
    );
    if (result.status == LoginStatus.cancelled) {
      return const ExternalProviderCancelled();
    }
    final token = result.accessToken?.tokenString;
    if (result.status != LoginStatus.success ||
        token == null ||
        token.isEmpty) {
      throw ExternalIdentityException(
        result.message ?? 'Facebook no entregó una credencial válida.',
      );
    }
    return ExternalProviderSuccess(
      ExternalProviderCredential(
        provider: ExternalAuthProvider.facebook,
        credential: token,
      ),
    );
  }

  Future<ExternalProviderResult> _signInApple() async {
    if (Platform.isAndroid &&
        (_appleServiceId.isEmpty || _appleRedirectUri.isEmpty)) {
      throw const ExternalIdentityException(
        'Falta configurar APPLE_SERVICE_ID y APPLE_REDIRECT_URI.',
      );
    }
    final rawNonce = generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
      webAuthenticationOptions: Platform.isAndroid
          ? WebAuthenticationOptions(
              clientId: _appleServiceId,
              redirectUri: Uri.parse(_appleRedirectUri),
            )
          : null,
    );
    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw const ExternalIdentityException(
        'Apple no entregó una credencial válida para PetLife.',
      );
    }
    return ExternalProviderSuccess(
      ExternalProviderCredential(
        provider: ExternalAuthProvider.apple,
        credential: idToken,
        nonce: rawNonce,
      ),
    );
  }

  @override
  Future<void> signOut() async {
    try {
      if (_googleInitialized) await _google.signOut();
    } catch (_) {}
    try {
      await _facebook.logOut();
    } catch (_) {}
    // Apple deliberately exposes no global provider logout operation.
  }
}
