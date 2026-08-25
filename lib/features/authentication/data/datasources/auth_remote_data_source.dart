// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';

import '../../../../core/constants/api_paths.dart';
import '../dto/auth_response_dto.dart';
import '../dto/user_dto.dart';
import '../../../legal/domain/entities/legal.dart';

/// Talks directly to the Identity service's REST endpoints. Never throws
/// [AppException]s itself — callers (the repository) are responsible for
/// mapping [DioException]s into typed failures.
class AuthRemoteDataSource {
  AuthRemoteDataSource({required Dio authenticatedDio, required Dio rawDio})
    : _authenticatedDio = authenticatedDio,
      _rawDio = rawDio;

  /// Used only for calls requiring a bearer token (`me`).
  final Dio _authenticatedDio;

  /// Used for anonymous authentication operations, including logout, whose
  /// contract authenticates the session through its refresh-token body.
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
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required List<LegalConsentSelection> legalConsents,
    String? phoneNumber,
  }) async {
    await _rawDio.post<Map<String, dynamic>>(
      ApiPaths.register,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'legalConsents': [
          for (final consent in legalConsents)
            {'type': consent.type, 'version': consent.version},
        ],
      },
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

  Future<void> logout({required String refreshToken}) async {
    await _rawDio.post<void>(
      ApiPaths.logout,
      data: {'refreshToken': refreshToken},
    );
  }

  Future<UserDto> getCurrentUser() async {
    final response = await _authenticatedDio.get<Map<String, dynamic>>(
      ApiPaths.me,
    );
    return UserDto.fromJson(response.data!);
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    await _authenticatedDio.put<void>(
      ApiPaths.me,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
      },
    );
  }

  Future<void> uploadProfilePhoto({
    required String fileName,
    required String contentType,
    required String imageBase64,
  }) async {
    await _authenticatedDio.post<void>(
      ApiPaths.mePhoto,
      data: {
        'fileName': fileName,
        'contentType': contentType,
        'imageBase64': imageBase64,
      },
    );
  }
}
