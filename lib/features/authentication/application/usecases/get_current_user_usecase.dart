import '../../../../core/result/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Fetches the current authenticated user's profile from the Identity
/// service (used on cold start to validate a persisted session).
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<User>> call() {
    return _repository.getCurrentUser();
  }
}
