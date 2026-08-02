import '../../../../core/result/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Encapsulates the registration business operation.
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<User>> call({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _repository.register(
      fullName: fullName,
      email: email,
      password: password,
    );
  }
}
