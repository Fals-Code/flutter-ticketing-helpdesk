import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<Either<Failure, AuthUser>, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(LoginParams params) {
    return repository.login(
      identifier: params.identifier,
      password: params.password,
    );
  }
}

class LoginParams {
  final String identifier;
  final String password;

  const LoginParams({
    required this.identifier,
    required this.password,
  });
}

class RegisterUseCase
    implements UseCase<Either<Failure, AuthUser>, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(RegisterParams params) {
    return repository.register(
      email: params.email,
      username: params.username,
      password: params.password,
      fullName: params.fullName,
    );
  }
}

class RegisterParams {
  final String email;
  final String username;
  final String password;
  final String fullName;

  const RegisterParams({
    required this.email,
    required this.username,
    required this.password,
    required this.fullName,
  });
}

class LogoutUseCase implements UseCase<Either<Failure, Unit>, NoParams> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => repository.logout();
}

class GetCurrentUserUseCase
    implements UseCase<Either<Failure, AuthUser>, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}

class ResetPasswordUseCase implements UseCase<Either<Failure, Unit>, String> {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String email) {
    return repository.resetPassword(email);
  }
}
