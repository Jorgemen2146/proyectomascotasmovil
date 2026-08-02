import '../../../../core/result/result.dart';
import '../../domain/repositories/auth_repository.dart';

/// Encapsulates the logout business operation (remote call + local
/// session cleanup, handled inside the repository).
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() {
    return _repository.logout();
  }
}
