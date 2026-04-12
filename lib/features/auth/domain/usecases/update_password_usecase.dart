import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class UpdatePasswordUseCase implements UseCase<Either<Failure, Unit>, String> {
  final AuthRepository repository;

  UpdatePasswordUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String params) async {
    return await repository.updatePassword(params);
  }
}
