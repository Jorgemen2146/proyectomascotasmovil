// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';

import '../../../../core/constants/api_paths.dart';
import '../dto/auth_response_dto.dart';
import '../dto/user_dto.dart';

/// Talks directly to the Identity service's REST endpoints. Never throws
/// [AppException]s itself — callers (the repository) are responsible for
/// mapping [DioException]s into typed failures.
class AuthRemoteDataSource {
  AuthRemoteDataSource({required Dio authenticatedDio, required Dio rawDio})
    : _authenticatedDio = authenticatedDio,
      _rawDio = rawDio;

  /// Used for calls requiring a bearer token (logout, me).
  final Dio _authenticatedDio;

  /// Used for calls that happen before a session exists (login, register).
  final Dio _rawDio;

  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    final response = await _rawDio.post<Map<String, dynamic>>(
      ApiPaths.login,
      data: {'email': email, 'password': password},
    );
    return AuthResponseDto.fromJson(response.data!);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _rawDio.post<void>(
      ApiPaths.register,
      data: {'fullName': fullName, 'email': email, 'password': password},
    );
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _rawDio.post<void>(
      ApiPaths.verifyEmail,
      data: {'email': email, 'code': code},
    );
  }

  Future<void> resendVerification({required String email}) async {
    await _rawDio.post<void>(
      ApiPaths.resendVerification,
      data: {'email': email},
    );
  }

  Future<void> logout() async {
    await _authenticatedDio.post<void>(ApiPaths.logout);
  }

  Future<UserDto> getCurrentUser() async {
    final response = await _authenticatedDio.get<Map<String, dynamic>>(
      ApiPaths.me,
    );
    return UserDto.fromJson(response.data!);
  }
}
