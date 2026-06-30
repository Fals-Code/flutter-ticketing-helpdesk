import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uts/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:uts/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:uts/features/auth/domain/repositories/auth_repository.dart';
import 'package:uts/features/auth/domain/usecases/auth_usecases.dart';
import 'package:uts/features/auth/domain/usecases/update_avatar_usecase.dart';
import 'package:uts/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:uts/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';

Future<void> initAuthDependencies(GetIt sl) async {
  sl.registerLazySingleton(() => AuthBloc(
        loginUseCase: sl(),
        registerUseCase: sl(),
        logoutUseCase: sl(),
        getCurrentUserUseCase: sl(),
        resetPasswordUseCase: sl(),
        updatePasswordUseCase: sl(),
        updateAvatarUseCase: sl(),
        updateProfileUseCase: sl(),
        supabaseClient: sl(),
      ));

  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePasswordUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAvatarUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      fcmService: sl(),
      sessionCleanupService: sl(),
    ),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => SupabaseAuthRemoteDataSourceImpl(sl()),
  );

  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerLazySingleton(() => Supabase.instance.client);
  }
}
