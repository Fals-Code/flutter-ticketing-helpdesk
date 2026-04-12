import 'package:get_it/get_it.dart';
import 'package:uts/core/services/local_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uts/features/notification/data/datasources/notification_remote_data_source.dart';
import 'package:uts/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:uts/features/notification/domain/repositories/notification_repository.dart';
import 'package:uts/features/notification/domain/usecases/notification_usecases.dart';
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';

Future<void> initNotificationDependencies(GetIt sl) async {
  // Datasource
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => SupabaseNotificationRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  // Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => MarkNotificationAsRead(sl()));
  sl.registerLazySingleton(() => WatchNotifications(sl()));

  // Services
  sl.registerLazySingleton(() => LocalNotificationService());

  // Bloc
  sl.registerLazySingleton(
    () => NotificationBloc(
      getNotifications: sl(),
      markNotificationAsRead: sl(),
      watchNotifications: sl(),
      localNotificationService: sl(),
    ),
  );
}
