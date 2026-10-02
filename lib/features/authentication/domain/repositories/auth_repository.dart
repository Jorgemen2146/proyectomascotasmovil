import '../../../../core/result/result.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../entities/user.dart';
import '../../../legal/domain/entities/legal.dart';
import '../entities/external_auth.dart';

/// Domain-facing contract for authentication operations. The data layer
/// provides the concrete implementation; application/presentation code only
/// ever depends on this abstraction.
abstract class AuthRepository {
  Future<Result<User>> login({required String email, required String password});

  Future<Result<ExternalAuthResult>> externalLogin({
    required ExternalProviderCredential credential,
  });

  Future<Result<User>> completeExternalRegistration({
    required String registrationToken,
    required String email,
    required String firstName,
    required String lastName,
    required List<LegalConsentSelection> legalConsents,
  });

  Future<Result<void>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required List<LegalConsentSelection> legalConsents,
    String? phoneNumber,
  });

  Future<Result<void>> verifyEmail({
    required String email,
    required String code,
  });

  Future<Result<void>> resendVerification({required String email});

  Future<Result<String>> forgotPassword({required String email});

  Future<Result<bool>> verifyResetCode({
    required String email,
    required String code,
  });

  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  });

  Future<Result<void>> logout();

  Future<Result<User>> getCurrentUser();

  Future<Result<void>> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  });

  Future<Result<void>> uploadProfilePhoto(SelectedPhoto photo);

  /// Whether a refresh token is currently persisted (does not guarantee
  /// it is still valid server-side).
  Future<bool> hasActiveSession();
}
