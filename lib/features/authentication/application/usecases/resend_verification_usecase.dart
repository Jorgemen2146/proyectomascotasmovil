import '../../../../core/result/result.dart';
import '../../domain/repositories/auth_repository.dart';

class ResendVerificationUseCase {
  const ResendVerificationUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) {
    return _repository.resendVerification(email: email);
  }
}
