import 'dart:async';

import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/core/services/photo_picker_service.dart';
import 'package:dogplatform/features/authentication/domain/entities/user.dart';
import 'package:dogplatform/features/authentication/domain/entities/external_auth.dart';
import 'package:dogplatform/features/authentication/domain/repositories/auth_repository.dart';
import 'package:dogplatform/features/legal/domain/entities/legal.dart';

class FakeAuthRepository implements AuthRepository {
  Result<User> loginResult = const Result.success(
    User(id: '1', email: 'dog@example.com', fullName: 'Dog User'),
  );
  Result<void> registerResult = const Result.success(null);
  Result<void> verifyResult = const Result.success(null);
  Result<void> resendResult = const Result.success(null);
  Result<String> forgotPasswordResult = const Result.success(
    'Si el correo está registrado, te enviaremos un código.',
  );
  Result<bool> verifyResetCodeResult = const Result.success(true);
  Result<void> resetPasswordResult = const Result.success(null);
  Completer<Result<String>>? forgotPasswordCompleter;
  Result<User> currentUserResult = const Result.failure(UnauthorizedFailure());
  Result<void> updateProfileResult = const Result.success(null);
  Result<void> uploadProfilePhotoResult = const Result.success(null);
  bool activeSession = false;
  Result<ExternalAuthResult> externalLoginResult = const Result.failure(
    UnknownFailure(),
  );
  Result<User> completeExternalRegistrationResult = const Result.failure(
    UnknownFailure(),
  );

  int loginCalls = 0;
  int registerCalls = 0;
  int verifyCalls = 0;
  int resendCalls = 0;
  int forgotPasswordCalls = 0;
  int verifyResetCodeCalls = 0;
  int resetPasswordCalls = 0;
  int logoutCalls = 0;
  String? lastEmail;
  String? lastCode;
  String? lastNewPassword;
  String? lastConfirmPassword;
  String? lastFirstName;
  String? lastLastName;
  String? lastPhoneNumber;
  SelectedPhoto? lastProfilePhoto;
  List<LegalConsentSelection> lastLegalConsents = const [];
  final List<String> profileEvents = [];

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
  Future<Result<ExternalAuthResult>> externalLogin({
    required ExternalProviderCredential credential,
  }) async {
    return externalLoginResult;
  }

  @override
  Future<Result<User>> completeExternalRegistration({
    required String registrationToken,
    required String email,
    required String firstName,
    required String lastName,
    required List<LegalConsentSelection> legalConsents,
  }) async {
    lastEmail = email;
    lastFirstName = firstName;
    lastLastName = lastName;
    lastLegalConsents = legalConsents;
    return completeExternalRegistrationResult;
  }

  @override
  Future<Result<void>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required List<LegalConsentSelection> legalConsents,
    String? phoneNumber,
  }) async {
    registerCalls++;
    lastFirstName = firstName;
    lastLastName = lastName;
    lastEmail = email;
    lastPhoneNumber = phoneNumber;
    lastLegalConsents = legalConsents;
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
  Future<Result<String>> forgotPassword({required String email}) async {
    forgotPasswordCalls++;
    lastEmail = email;
    if (forgotPasswordCompleter case final completer?) {
      return completer.future;
    }
    return forgotPasswordResult;
  }

  @override
  Future<Result<bool>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    verifyResetCodeCalls++;
    lastEmail = email;
    lastCode = code;
    return verifyResetCodeResult;
  }

  @override
  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    resetPasswordCalls++;
    lastEmail = email;
    lastCode = code;
    lastNewPassword = newPassword;
    lastConfirmPassword = confirmPassword;
    return resetPasswordResult;
  }

  @override
  Future<Result<void>> logout() async {
    logoutCalls++;
    return const Result.success(null);
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    profileEvents.add('getCurrentUser');
    return currentUserResult;
  }

  @override
  Future<Result<void>> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    profileEvents.add('updateProfile');
    if (updateProfileResult.isFailure) return updateProfileResult;
    final current = currentUserResult.valueOrNull;
    final user = User(
      id: current?.id ?? '1',
      email: current?.email ?? 'dog@example.com',
      fullName: '$firstName $lastName',
      phoneNumber: phoneNumber,
      profilePhotoUrl: current?.profilePhotoUrl,
    );
    currentUserResult = Result.success(user);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> uploadProfilePhoto(SelectedPhoto photo) async {
    profileEvents.add('uploadProfilePhoto');
    lastProfilePhoto = photo;
    if (uploadProfilePhotoResult.isFailure) {
      return uploadProfilePhotoResult;
    }
    final current = currentUserResult.valueOrNull;
    if (current != null) {
      currentUserResult = Result.success(
        current.copyWith(profilePhotoUrl: '/api/v1/auth/me/photo/content'),
      );
    }
    return const Result.success(null);
  }

  @override
  Future<bool> hasActiveSession() async => activeSession;
}
