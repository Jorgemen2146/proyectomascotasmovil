import '../../../../core/result/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Encapsulates the login business operation, keeping presentation code
/// free of direct repository calls.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<User>> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}
