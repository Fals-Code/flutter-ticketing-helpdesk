import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// UseCase untuk Login.
class LoginUseCase implements UseCase<Either<Failure, AuthUser>, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(LoginParams params) async {
    return await repository.login(email: params.email, password: params.password);
  }
}

class LoginParams {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});
}

/// UseCase untuk Registrasi.
class RegisterUseCase implements UseCase<Either<Failure, AuthUser>, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(RegisterParams params) async {
    return await repository.register(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
    );
  }
}

class RegisterParams {
  final String email;
  final String password;
  final String fullName;
  const RegisterParams({
    required this.email,
    required this.password,
    required this.fullName,
  });
}

/// UseCase untuk Logout.
class LogoutUseCase implements UseCase<Either<Failure, Unit>, NoParams> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    return await repository.logout();
  }
}

/// UseCase untuk Cek Sesi (Get Current User).
class GetCurrentUserUseCase implements UseCase<Either<Failure, AuthUser>, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}

/// UseCase untuk Reset Password.
class ResetPasswordUseCase implements UseCase<Either<Failure, Unit>, String> {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String email) async {
    return await repository.resetPassword(email);
  }
}
