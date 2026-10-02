import 'package:dio/dio.dart';
import 'package:dogplatform/core/constants/api_paths.dart';
import 'package:dogplatform/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dogplatform/features/legal/domain/entities/legal.dart';
import 'package:dogplatform/features/authentication/domain/entities/external_auth.dart';

void main() {
  late _RecordingDio rawDio;
  late _RecordingDio authenticatedDio;
  late AuthRemoteDataSource dataSource;

  setUp(() {
    rawDio = _RecordingDio();
    authenticatedDio = _RecordingDio();
    dataSource = AuthRemoteDataSource(
      authenticatedDio: authenticatedDio.dio,
      rawDio: rawDio.dio,
    );
  });

  test('Register coincide exactamente con Postman', () async {
    await dataSource.register(
      firstName: 'Jorge',
      lastName: 'Test',
      email: 'jorge@test.com',
      password: 'Testing123',
      legalConsents: const [
        LegalConsentSelection(type: 'TermsAndConditions', version: '2.1'),
        LegalConsentSelection(type: 'PrivacyPolicy', version: '3.0'),
      ],
      phoneNumber: null,
    );

    expect(rawDio.lastRequest?.method, 'POST');
    expect(rawDio.lastRequest?.path, ApiPaths.register);
    expect(rawDio.lastRequest?.data, {
      'firstName': 'Jorge',
      'lastName': 'Test',
      'email': 'jorge@test.com',
      'password': 'Testing123',
      'phoneNumber': null,
      'legalConsents': [
        {'type': 'TermsAndConditions', 'version': '2.1'},
        {'type': 'PrivacyPolicy', 'version': '3.0'},
      ],
    });
  });

  test('Login coincide con Postman y deserializa respuesta plana', () async {
    rawDio.responseData = {
      'userId': '11111111-1111-1111-1111-111111111111',
      'firstName': 'Jorge',
      'lastName': 'Test',
      'email': 'jorge@test.com',
      'accessToken': 'access',
      'accessTokenExpiresAtUtc': '2030-01-01T00:00:00Z',
      'refreshToken': 'refresh',
      'refreshTokenExpiresAtUtc': '2031-01-01T00:00:00Z',
    };

    final response = await dataSource.login(
      email: 'jorge@test.com',
      password: 'Testing123',
    );

    expect(rawDio.lastRequest?.method, 'POST');
    expect(rawDio.lastRequest?.path, ApiPaths.login);
    expect(rawDio.lastRequest?.data, {
      'email': 'jorge@test.com',
      'password': 'Testing123',
    });
    expect(response.userId, '11111111-1111-1111-1111-111111111111');
    expect(response.firstName, 'Jorge');
  });

  test('Google, Facebook y Apple coinciden con Postman', () async {
    rawDio.responseData = _authResponse;
    await dataSource.externalLogin(
      credential: const ExternalProviderCredential(
        provider: ExternalAuthProvider.google,
        credential: 'google-id-token',
      ),
    );
    expect(rawDio.lastRequest?.path, ApiPaths.externalGoogle);
    expect(rawDio.lastRequest?.data, {'idToken': 'google-id-token'});

    await dataSource.externalLogin(
      credential: const ExternalProviderCredential(
        provider: ExternalAuthProvider.facebook,
        credential: 'facebook-access-token',
      ),
    );
    expect(rawDio.lastRequest?.path, ApiPaths.externalFacebook);
    expect(rawDio.lastRequest?.data, {'accessToken': 'facebook-access-token'});

    await dataSource.externalLogin(
      credential: const ExternalProviderCredential(
        provider: ExternalAuthProvider.apple,
        credential: 'apple-id-token',
        nonce: 'original-nonce',
      ),
    );
    expect(rawDio.lastRequest?.path, ApiPaths.externalApple);
    expect(rawDio.lastRequest?.data, {
      'idToken': 'apple-id-token',
      'nonce': 'original-nonce',
    });
  });

  test('Complete External Registration coincide con Postman', () async {
    rawDio.responseData = _authResponse;
    await dataSource.completeExternalRegistration(
      registrationToken: 'registration-token',
      email: 'jorge@test.com',
      firstName: 'Jorge',
      lastName: 'Test',
      legalConsents: const [
        LegalConsentSelection(type: 'TermsAndConditions', version: '1.0'),
        LegalConsentSelection(type: 'PrivacyPolicy', version: '1.0'),
      ],
    );
    expect(rawDio.lastRequest?.path, ApiPaths.completeExternalRegistration);
    expect(rawDio.lastRequest?.data, {
      'registrationToken': 'registration-token',
      'email': 'jorge@test.com',
      'firstName': 'Jorge',
      'lastName': 'Test',
      'legalConsents': _consents,
    });
  });

  test('Verify Email y Resend coinciden con Postman', () async {
    await dataSource.verifyEmail(email: 'jorge@test.com', code: '123456');
    expect(rawDio.lastRequest?.path, ApiPaths.verifyEmail);
    expect(rawDio.lastRequest?.data, {
      'email': 'jorge@test.com',
      'code': '123456',
    });

    await dataSource.resendVerification(email: 'jorge@test.com');
    expect(rawDio.lastRequest?.path, ApiPaths.resendVerification);
    expect(rawDio.lastRequest?.data, {'email': 'jorge@test.com'});
  });

  test('Password Recovery coincide exactamente con Postman', () async {
    rawDio.responseData = {
      'message': 'Si el correo está registrado, te enviaremos un código.',
    };
    final forgot = await dataSource.forgotPassword(email: 'jorge@test.com');
    expect(rawDio.lastRequest?.path, ApiPaths.forgotPassword);
    expect(rawDio.lastRequest?.data, {'email': 'jorge@test.com'});
    expect(forgot.message, contains('te enviaremos un código'));

    rawDio.responseData = {'valid': true};
    final verification = await dataSource.verifyResetCode(
      email: 'jorge@test.com',
      code: '483921',
    );
    expect(rawDio.lastRequest?.path, ApiPaths.verifyResetCode);
    expect(rawDio.lastRequest?.data, {
      'email': 'jorge@test.com',
      'code': '483921',
    });
    expect(verification.valid, isTrue);

    await dataSource.resetPassword(
      email: 'jorge@test.com',
      code: '483921',
      newPassword: 'Testing456',
      confirmPassword: 'Testing456',
    );
    expect(rawDio.lastRequest?.path, ApiPaths.resetPassword);
    expect(rawDio.lastRequest?.data, {
      'email': 'jorge@test.com',
      'code': '483921',
      'newPassword': 'Testing456',
      'confirmPassword': 'Testing456',
    });
    expect(authenticatedDio.lastRequest, isNull);
  });

  test('Logout es anónimo y envía refreshToken', () async {
    await dataSource.logout(refreshToken: 'refresh');

    expect(rawDio.lastRequest?.method, 'POST');
    expect(rawDio.lastRequest?.path, ApiPaths.logout);
    expect(rawDio.lastRequest?.data, {'refreshToken': 'refresh'});
    expect(authenticatedDio.lastRequest, isNull);
  });

  test('Me usa JWT y deserializa userId, firstName y lastName', () async {
    authenticatedDio.responseData = {
      'userId': '11111111-1111-1111-1111-111111111111',
      'email': 'jorge@test.com',
      'firstName': 'Jorge',
      'lastName': 'Test',
      'profilePhotoUrl': '/api/v1/auth/me/photo/content',
    };

    final user = await dataSource.getCurrentUser();

    expect(authenticatedDio.lastRequest?.method, 'GET');
    expect(authenticatedDio.lastRequest?.path, ApiPaths.me);
    expect(user.userId, '11111111-1111-1111-1111-111111111111');
    expect(user.toDomain().fullName, 'Jorge Test');
    expect(user.toDomain().profilePhotoUrl, '/api/v1/auth/me/photo/content');
    expect(rawDio.lastRequest, isNull);
  });

  test('foto de perfil usa POST autenticado con Base64 puro', () async {
    await dataSource.uploadProfilePhoto(
      fileName: 'jorge.jpg',
      contentType: 'image/jpeg',
      imageBase64: 'AQIDBA==',
    );

    expect(authenticatedDio.lastRequest?.method, 'POST');
    expect(authenticatedDio.lastRequest?.path, ApiPaths.mePhoto);
    expect(authenticatedDio.lastRequest?.data, {
      'fileName': 'jorge.jpg',
      'contentType': 'image/jpeg',
      'imageBase64': 'AQIDBA==',
    });
    expect(rawDio.lastRequest, isNull);
  });

  test('Editar perfil usa PUT /me sin enviar email', () async {
    await dataSource.updateProfile(
      firstName: 'Jorge',
      lastName: 'Gonzales',
      phoneNumber: '+51 987654321',
    );

    expect(authenticatedDio.lastRequest?.method, 'PUT');
    expect(authenticatedDio.lastRequest?.path, ApiPaths.me);
    expect(authenticatedDio.lastRequest?.data, {
      'firstName': 'Jorge',
      'lastName': 'Gonzales',
      'phoneNumber': '+51 987654321',
    });
    expect(
      (authenticatedDio.lastRequest?.data as Map).containsKey('email'),
      isFalse,
    );
  });
}

const _consents = [
  {'type': 'TermsAndConditions', 'version': '1.0'},
  {'type': 'PrivacyPolicy', 'version': '1.0'},
];

final _authResponse = <String, dynamic>{
  'userId': '11111111-1111-1111-1111-111111111111',
  'firstName': 'Jorge',
  'lastName': 'Test',
  'email': 'jorge@test.com',
  'accessToken': 'access',
  'accessTokenExpiresAtUtc': '2030-01-01T00:00:00Z',
  'refreshToken': 'refresh',
  'refreshTokenExpiresAtUtc': '2031-01-01T00:00:00Z',
};

class _RecordingDio {
  _RecordingDio() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          lastRequest = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: options.path == ApiPaths.register ? 201 : 200,
              data: responseData,
            ),
          );
        },
      ),
    );
  }

  final Dio dio = Dio();
  RequestOptions? lastRequest;
  dynamic responseData = <String, dynamic>{};
}
