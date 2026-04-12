import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/admin_report_entity.dart';
import '../repositories/admin_repository.dart';

class GetUsersUseCase implements UseCase<Either<Failure, List<AuthUser>>, NoParams> {
  final AdminRepository repository;
  GetUsersUseCase(this.repository);

  @override
  Future<Either<Failure, List<AuthUser>>> call(NoParams params) async {
    return await repository.getUsers();
  }
}

class UpdateUserRoleUseCase implements UseCase<Either<Failure, void>, UpdateRoleParams> {
  final AdminRepository repository;
  UpdateUserRoleUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateRoleParams params) async {
    return await repository.updateUserRole(params.userId, params.newRole);
  }
}

class GetAdminReportsUseCase implements UseCase<Either<Failure, AdminReport>, NoParams> {
  final AdminRepository repository;
  GetAdminReportsUseCase(this.repository);

  @override
  Future<Either<Failure, AdminReport>> call(NoParams params) async {
    return await repository.getAdminReports();
  }
}

class UpdateRoleParams {
  final String userId;
  final int newRole;
  UpdateRoleParams({required this.userId, required this.newRole});
}
