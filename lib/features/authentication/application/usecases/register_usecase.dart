import '../../../../core/result/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../legal/domain/entities/legal.dart';

/// Encapsulates the registration business operation.
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required List<LegalConsentSelection> legalConsents,
    String? phoneNumber,
  }) {
    return _repository.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      legalConsents: legalConsents,
      phoneNumber: phoneNumber,
    );
  }
}
