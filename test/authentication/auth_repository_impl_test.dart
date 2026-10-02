import 'package:dio/dio.dart';
import 'package:dogplatform/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:dogplatform/features/authentication/data/dto/auth_response_dto.dart';
import 'package:dogplatform/features/authentication/data/dto/password_recovery_dtos.dart';
import 'package:dogplatform/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:dogplatform/core/storage/secure_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dogplatform/features/legal/domain/entities/legal.dart';
import 'package:dogplatform/features/authentication/domain/entities/external_auth.dart';

void main() {
  test('Register y Verify Email no guardan tokens', () async {
    final storage = _RecordingTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: _FakeRemoteDataSource(),
      tokenStorage: storage,
    );

    final register = await repository.register(
      firstName: 'Dog',
      lastName: 'User',
      email: 'dog@example.com',
      password: 'password',
      legalConsents: const [
        LegalConsentSelection(type: 'TermsAndConditions', version: '1.0'),
      ],
      phoneNumber: null,
    );
    final verify = await repository.verifyEmail(
      email: 'dog@example.com',
      code: '123456',
    );

    expect(register.isSuccess, isTrue);
    expect(verify.isSuccess, isTrue);
    expect(storage.saveCalls, 0);
  });

  test('Login exitoso sí conserva la sesión', () async {
    final storage = _RecordingTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: _FakeRemoteDataSource(),
      tokenStorage: storage,
    );

    final login = await repository.login(
      email: 'dog@example.com',
      password: 'password',
    );

    expect(login.isSuccess, isTrue);
    expect(storage.saveCalls, 1);
  });

  test('Login externo exitoso guarda sólo la sesión DogPlatform', () async {
    final storage = _RecordingTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: _FakeRemoteDataSource(),
      tokenStorage: storage,
    );

    final result = await repository.externalLogin(
      credential: const ExternalProviderCredential(
        provider: ExternalAuthProvider.google,
        credential: 'provider-token',
      ),
    );

    expect(result.valueOrNull, isA<ExternalAuthAuthenticated>());
    expect(storage.saveCalls, 1);
    expect(storage.accessToken, 'access');
    expect(storage.savedRefreshToken, 'refresh');
  });

  test('422 con registrationToken solicita sólo los datos faltantes', () async {
    final storage = _RecordingTokenStorage();
    final remote = _FakeRemoteDataSource()
      ..externalError = _externalError(422, {
        'registrationToken': 'registration-ticket',
        'missingFields': ['email'],
      });
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      tokenStorage: storage,
    );

    final result = await repository.externalLogin(
      credential: const ExternalProviderCredential(
        provider: ExternalAuthProvider.facebook,
        credential: 'provider-token',
      ),
    );

    final registration = result.valueOrNull as ExternalRegistrationRequired;
    expect(registration.registrationToken, 'registration-ticket');
    expect(registration.missingFields, {'email'});
    expect(storage.saveCalls, 0);
  });

  test(
    'Account link required se traduce sin vincular silenciosamente',
    () async {
      final remote = _FakeRemoteDataSource()
        ..externalError = _externalError(409, {
          'code': 'EXTERNAL_ACCOUNT_LINK_REQUIRED',
        });
      final repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        tokenStorage: _RecordingTokenStorage(),
      );

      final result = await repository.externalLogin(
        credential: const ExternalProviderCredential(
          provider: ExternalAuthProvider.apple,
          credential: 'provider-token',
          nonce: 'nonce',
        ),
      );

      expect(result.failureOrNull?.message, contains('Ya existe una cuenta'));
      expect(result.failureOrNull?.message, contains('PetLife'));
    },
  );

  test('Logout envía el refreshToken y siempre limpia la sesión', () async {
    final storage = _RecordingTokenStorage()..refreshToken = 'refresh';
    final remote = _FakeRemoteDataSource();
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      tokenStorage: storage,
    );

    await repository.logout();

    expect(remote.logoutRefreshToken, 'refresh');
    expect(storage.clearCalls, 1);
  });

  test(
    'Password Recovery traduce los códigos reales sin exponer Dio',
    () async {
      const cases = {
        'PASSWORD_RESET_CODE_INVALID': 'El código ingresado no es correcto.',
        'PASSWORD_RESET_CODE_EXPIRED':
            'El código ha vencido. Solicita uno nuevo.',
        'PASSWORD_RESET_CODE_LOCKED':
            'Solicita un nuevo código para continuar.',
        'PASSWORD_RESET_PASSWORD_INVALID':
            'La nueva contraseña no cumple los requisitos de seguridad.',
      };

      for (final entry in cases.entries) {
        final remote = _FakeRemoteDataSource()
          ..recoveryError = DioException(
            requestOptions: RequestOptions(path: '/password-recovery'),
            response: Response<dynamic>(
              requestOptions: RequestOptions(path: '/password-recovery'),
              statusCode: 400,
              data: {'error': entry.key},
            ),
            type: DioExceptionType.badResponse,
          );
        final repository = AuthRepositoryImpl(
          remoteDataSource: remote,
          tokenStorage: _RecordingTokenStorage(),
        );

        final result = entry.key == 'PASSWORD_RESET_PASSWORD_INVALID'
            ? await repository.resetPassword(
                email: 'dog@example.com',
                code: '483921',
                newPassword: 'invalid',
                confirmPassword: 'invalid',
              )
            : await repository.verifyResetCode(
                email: 'dog@example.com',
                code: '483921',
              );

        expect(result.failureOrNull?.message, entry.value);
        expect(result.failureOrNull?.message, isNot(contains('DioException')));
      }
    },
  );
}

class _FakeRemoteDataSource extends AuthRemoteDataSource {
  _FakeRemoteDataSource() : super(authenticatedDio: Dio(), rawDio: Dio());

  String? logoutRefreshToken;
  DioException? recoveryError;
  DioException? externalError;

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required List<LegalConsentSelection> legalConsents,
    String? phoneNumber,
  }) async {}

  @override
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {}

  @override
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    return AuthResponseDto(
      userId: '1',
      firstName: 'Dog',
      lastName: 'User',
      email: 'dog@example.com',
      accessToken: 'access',
      accessTokenExpiresAtUtc: DateTime(2030),
      refreshToken: 'refresh',
      refreshTokenExpiresAtUtc: DateTime(2031),
    );
  }

  @override
  Future<AuthResponseDto> externalLogin({
    required ExternalProviderCredential credential,
  }) async {
    if (externalError case final error?) throw error;
    return login(email: 'dog@example.com', password: 'unused');
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    logoutRefreshToken = refreshToken;
  }

  @override
  Future<VerifyResetCodeResponseDto> verifyResetCode({
    required String email,
    required String code,
  }) async {
    if (recoveryError case final error?) throw error;
    return const VerifyResetCodeResponseDto(valid: true);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (recoveryError case final error?) throw error;
  }
}

class _RecordingTokenStorage extends SecureTokenStorage {
  int saveCalls = 0;
  int clearCalls = 0;
  String? refreshToken;
  String? accessToken;
  String? savedRefreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    saveCalls++;
    this.accessToken = accessToken;
    savedRefreshToken = refreshToken;
  }

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> clear() async {
    clearCalls++;
  }
}

DioException _externalError(int statusCode, Map<String, dynamic> data) {
  final request = RequestOptions(path: '/external');
  return DioException(
    requestOptions: request,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: statusCode,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );
}
