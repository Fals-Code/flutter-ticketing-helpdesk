import 'package:get_it/get_it.dart';
import '../data/datasources/admin_remote_data_source.dart';
import '../data/repositories/admin_repository_impl.dart';
import '../domain/repositories/admin_repository.dart';
import '../domain/usecases/admin_usecases.dart';
import '../presentation/bloc/admin_bloc.dart';

Future<void> initAdmin(GetIt sl) async {
  // BLoC
  sl.registerFactory(() => AdminBloc(
        getUsersUseCase: sl(),
        updateUserRoleUseCase: sl(),
        getAdminReportsUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetUsersUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserRoleUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminReportsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => SupabaseAdminRemoteDataSourceImpl(sl()),
  );
}
