import '../../../../core/result/result.dart';
import '../../domain/repositories/auth_repository.dart';

class VerifyEmailUseCase {
  const VerifyEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email, required String code}) {
    return _repository.verifyEmail(email: email, code: code);
  }
}
