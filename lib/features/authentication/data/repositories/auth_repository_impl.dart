// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/dio_exception_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../dto/auth_response_dto.dart';
import '../../../legal/domain/entities/legal.dart';

/// Concrete [AuthRepository] backed by [AuthRemoteDataSource] and
/// [SecureTokenStorage]. Responsible for persisting/clearing tokens as a
/// side effect of successful/failed auth operations.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureTokenStorage tokenStorage,
  }) : _remoteDataSource = remoteDataSource,
       _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final SecureTokenStorage _tokenStorage;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) {
    return _runAuthCall(
      () => _remoteDataSource.login(email: email, password: password),
    );
  }

  @override
  Future<Result<void>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required List<LegalConsentSelection> legalConsents,
    String? phoneNumber,
  }) {
    return _runRegistrationCall(
      () => _remoteDataSource.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        legalConsents: legalConsents,
        phoneNumber: phoneNumber,
      ),
    );
  }

  @override
  Future<Result<void>> verifyEmail({
    required String email,
    required String code,
  }) {
    return _runVoidCall(
      () => _remoteDataSource.verifyEmail(email: email, code: code),
    );
  }

  @override
  Future<Result<void>> resendVerification({required String email}) {
    return _runVoidCall(
      () => _remoteDataSource.resendVerification(email: email),
    );
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _remoteDataSource.logout(refreshToken: refreshToken);
      }
    } on DioException {
      // Best-effort: proceed to clear the local session regardless.
    } finally {
      await _tokenStorage.clear();
    }
    return const Result.success(null);
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final dto = await _remoteDataSource.getCurrentUser();
      return Result.success(dto.toDomain());
    } on DioException catch (e) {
      return Result.failure(
        mapExceptionToFailure(mapDioExceptionToAppException(e)),
      );
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) => _runVoidCall(
    () => _remoteDataSource.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    ),
  );

  @override
  Future<Result<void>> uploadProfilePhoto(SelectedPhoto photo) async {
    try {
      final prepared = await preparePhotoUpload(photo);
      await _remoteDataSource.uploadProfilePhoto(
        fileName: prepared.fileName,
        contentType: prepared.contentType,
        imageBase64: prepared.imageBase64,
      );
      return const Result.success(null);
    } on PhotoValidationException catch (error) {
      return Result.failure(ValidationFailure(error.message));
    } on DioException catch (e) {
      return Result.failure(
        mapExceptionToFailure(mapDioExceptionToAppException(e)),
      );
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<bool> hasActiveSession() => _tokenStorage.hasValidSession();

  Future<Result<User>> _runAuthCall(
    Future<AuthResponseDto> Function() call,
  ) async {
    try {
      final response = await call();
      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      return Result.success(response.toDomain());
    } on DioException catch (e) {
      return Result.failure(
        mapExceptionToFailure(mapDioExceptionToAppException(e)),
      );
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  Future<Result<void>> _runVoidCall(Future<void> Function() call) async {
    try {
      await call();
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.failure(
        mapExceptionToFailure(mapDioExceptionToAppException(e)),
      );
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  Future<Result<void>> _runRegistrationCall(
    Future<void> Function() call,
  ) async {
    try {
      await call();
      return const Result.success(null);
    } on DioException catch (error) {
      final data = error.response?.data;
      final code = data is Map ? data['code']?.toString() : null;
      final message = switch (code) {
        'LEGAL_CONSENT_REQUIRED' => 'Debes aceptar los documentos requeridos.',
        'LEGAL_DOCUMENT_VERSION_INVALID' =>
          'Los documentos legales se actualizaron. Revísalos nuevamente.',
        'LEGAL_DOCUMENT_NOT_FOUND' => 'No pudimos cargar el documento.',
        _ => null,
      };
      if (message != null) return Result.failure(ValidationFailure(message));
      return Result.failure(
        mapExceptionToFailure(mapDioExceptionToAppException(error)),
      );
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }
}
