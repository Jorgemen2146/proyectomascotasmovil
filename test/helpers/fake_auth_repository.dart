import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/authentication/domain/entities/user.dart';
import 'package:dogplatform/features/authentication/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  Result<User> loginResult = const Result.success(
    User(id: '1', email: 'dog@example.com', fullName: 'Dog User'),
  );
  Result<void> registerResult = const Result.success(null);
  Result<void> verifyResult = const Result.success(null);
  Result<void> resendResult = const Result.success(null);
  Result<User> currentUserResult = const Result.failure(UnauthorizedFailure());
  bool activeSession = false;

  int loginCalls = 0;
  int registerCalls = 0;
  int verifyCalls = 0;
  int resendCalls = 0;
  String? lastEmail;
  String? lastCode;
  String? lastFirstName;
  String? lastLastName;
  String? lastPhoneNumber;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastEmail = email;
    return loginResult;
  }

  @override
  Future<Result<void>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    registerCalls++;
    lastFirstName = firstName;
    lastLastName = lastName;
    lastEmail = email;
    lastPhoneNumber = phoneNumber;
    return registerResult;
  }

  @override
  Future<Result<void>> verifyEmail({
    required String email,
    required String code,
  }) async {
    verifyCalls++;
    lastEmail = email;
    lastCode = code;
    return verifyResult;
  }

  @override
  Future<Result<void>> resendVerification({required String email}) async {
    resendCalls++;
    lastEmail = email;
    return resendResult;
  }

  @override
  Future<Result<void>> logout() async => const Result.success(null);

  @override
  Future<Result<User>> getCurrentUser() async => currentUserResult;

  @override
  Future<bool> hasActiveSession() async => activeSession;
}
