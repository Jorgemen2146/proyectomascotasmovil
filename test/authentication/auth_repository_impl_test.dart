import 'package:dio/dio.dart';
import 'package:dogplatform/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:dogplatform/features/authentication/data/dto/auth_response_dto.dart';
import 'package:dogplatform/features/authentication/data/dto/user_dto.dart';
import 'package:dogplatform/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:dogplatform/core/storage/secure_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Register y Verify Email no guardan tokens', () async {
    final storage = _RecordingTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: _FakeRemoteDataSource(),
      tokenStorage: storage,
    );

    final register = await repository.register(
      fullName: 'Dog User',
      email: 'dog@example.com',
      password: 'password',
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
}

class _FakeRemoteDataSource extends AuthRemoteDataSource {
  _FakeRemoteDataSource() : super(authenticatedDio: Dio(), rawDio: Dio());

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
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
    return const AuthResponseDto(
      accessToken: 'access',
      refreshToken: 'refresh',
      user: UserDto(id: '1', email: 'dog@example.com', fullName: 'Dog User'),
    );
  }
}

class _RecordingTokenStorage extends SecureTokenStorage {
  int saveCalls = 0;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    saveCalls++;
  }
}
