import '../../../../core/result/result.dart';
import '../entities/user.dart';

/// Domain-facing contract for authentication operations. The data layer
/// provides the concrete implementation; application/presentation code only
/// ever depends on this abstraction.
abstract class AuthRepository {
  Future<Result<User>> login({required String email, required String password});

  Future<Result<void>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  });

  Future<Result<void>> verifyEmail({
    required String email,
    required String code,
  });

  Future<Result<void>> resendVerification({required String email});

  Future<Result<void>> logout();

  Future<Result<User>> getCurrentUser();

  Future<Result<User>> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  });

  /// Whether a refresh token is currently persisted (does not guarantee
  /// it is still valid server-side).
  Future<bool> hasActiveSession();
}
