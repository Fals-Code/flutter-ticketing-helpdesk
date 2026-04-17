import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/admin_report_entity.dart';

import '../entities/app_settings_entity.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<AuthUser>>> getUsers();
  Future<Either<Failure, void>> updateUserRole(String userId, int newRole);
  Future<Either<Failure, AdminReport>> getAdminReports({DateTime? startDate, DateTime? endDate});
  Future<Either<Failure, AppSettings>> getAppSettings();
  Future<Either<Failure, void>> updateAppSettings(AppSettings settings);
}
