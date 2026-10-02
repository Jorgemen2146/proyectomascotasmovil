import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/services/native_external_identity_service.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/services/external_identity_service.dart';
import 'usecases/get_current_user_usecase.dart';
import 'usecases/login_usecase.dart';
import 'usecases/logout_usecase.dart';
import 'usecases/resend_verification_usecase.dart';
import 'usecases/register_usecase.dart';
import 'usecases/verify_email_usecase.dart';

/// Dependency wiring for the authentication feature. Kept in one place so
/// the composition root (`main.dart`) never needs to know about internal
/// feature classes.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    authenticatedDio: ref.read(gatewayDioProvider),
    rawDio: ref.read(gatewayRawDioProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    tokenStorage: ref.read(secureTokenStorageProvider),
  );
});

final externalIdentityServiceProvider = Provider<ExternalIdentityService>((
  ref,
) {
  return NativeExternalIdentityService();
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.read(authRepositoryProvider));
});

final verifyEmailUseCaseProvider = Provider<VerifyEmailUseCase>((ref) {
  return VerifyEmailUseCase(ref.read(authRepositoryProvider));
});

final resendVerificationUseCaseProvider = Provider<ResendVerificationUseCase>((
  ref,
) {
  return ResendVerificationUseCase(ref.read(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.read(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});
