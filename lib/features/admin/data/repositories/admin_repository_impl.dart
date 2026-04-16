import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/admin_report_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<AuthUser>>> getUsers() async {
    try {
      final users = await remoteDataSource.getUsers();
      return Right(users.map((u) => u.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserRole(String userId, int newRole) async {
    try {
      await remoteDataSource.updateUserRole(userId, newRole);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminReport>> getAdminReports({DateTime? startDate, DateTime? endDate}) async {
    try {
      final report = await remoteDataSource.getAdminReports(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(report.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
