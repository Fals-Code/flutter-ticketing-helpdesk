import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_settings_entity.dart';
import '../repositories/admin_repository.dart';

class GetAppSettingsUseCase implements UseCase<Either<Failure, AppSettings>, NoParams> {
  final AdminRepository repository;
  GetAppSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, AppSettings>> call(NoParams params) async {
    return await repository.getAppSettings();
  }
}

class UpdateAppSettingsUseCase implements UseCase<Either<Failure, void>, AppSettings> {
  final AdminRepository repository;
  UpdateAppSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AppSettings params) async {
    return await repository.updateAppSettings(params);
  }
}
