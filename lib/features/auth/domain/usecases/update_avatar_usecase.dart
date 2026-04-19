import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class UpdateAvatarUseCase implements UseCase<Either<Failure, String>, File> {
  final AuthRepository repository;

  UpdateAvatarUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(File image) async {
    return await repository.updateAvatar(image);
  }
}
