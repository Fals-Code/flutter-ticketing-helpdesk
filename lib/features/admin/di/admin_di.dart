import 'package:get_it/get_it.dart';
import 'package:uts/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:uts/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:uts/features/admin/domain/repositories/admin_repository.dart';
import 'package:uts/features/admin/domain/usecases/admin_usecases.dart';
import 'package:uts/features/admin/domain/usecases/app_settings_usecases.dart';
import 'package:uts/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:uts/features/admin/presentation/bloc/settings/app_settings_bloc.dart';

Future<void> initAdmin(GetIt sl) async {
  // BLoC
  sl.registerFactory(() => AdminBloc(
        getUsersUseCase: sl(),
        updateUserRoleUseCase: sl(),
        getAdminReportsUseCase: sl(),
      ));
  sl.registerFactory(() => AppSettingsBloc(
        getAppSettingsUseCase: sl(),
        updateAppSettingsUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetUsersUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserRoleUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminReportsUseCase(sl()));
  sl.registerLazySingleton(() => GetAppSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAppSettingsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => SupabaseAdminRemoteDataSourceImpl(sl()),
  );
}
