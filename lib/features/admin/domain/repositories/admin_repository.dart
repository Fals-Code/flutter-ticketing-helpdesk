import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/admin_report_entity.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<AuthUser>>> getUsers();
  Future<Either<Failure, void>> updateUserRole(String userId, int newRole);
  Future<Either<Failure, AdminReport>> getAdminReports();
}
