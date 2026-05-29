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

class UpdateUserDetailsUseCase implements UseCase<Either<Failure, void>, UpdateDetailsParams> {
  final AdminRepository repository;
  UpdateUserDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateDetailsParams params) async {
    return await repository.updateUserDetails(params.userId, params.fullName, params.email);
  }
}

class GetAdminReportsUseCase implements UseCase<Either<Failure, AdminReport>, GetReportParams> {
  final AdminRepository repository;
  GetAdminReportsUseCase(this.repository);

  @override
  Future<Either<Failure, AdminReport>> call(GetReportParams params) async {
    return await repository.getAdminReports(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetReportParams {
  final DateTime? startDate;
  final DateTime? endDate;

  GetReportParams({this.startDate, this.endDate});
}

class UpdateRoleParams {
  final String userId;
  final int newRole;
  UpdateRoleParams({required this.userId, required this.newRole});
}

class UpdateDetailsParams {
  final String userId;
  final String fullName;
  final String email;
  UpdateDetailsParams({required this.userId, required this.fullName, required this.email});
}
