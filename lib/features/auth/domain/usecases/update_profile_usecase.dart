import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileParams extends Equatable {
  final String fullName;
  final String? email;
  const UpdateProfileParams({required this.fullName, this.email});

  @override
  List<Object?> get props => [fullName, email];
}

/// Use Case untuk memperbarui nama lengkap profil user.
class UpdateProfileUseCase
    implements UseCase<Either<Failure, Unit>, UpdateProfileParams> {
  final AuthRepository repository;
  const UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateProfileParams params) {
    return repository.updateProfile(fullName: params.fullName);
  }
}
