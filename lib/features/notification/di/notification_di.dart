import 'package:get_it/get_it.dart';
import 'package:uts/core/services/local_notification_service.dart';
import 'package:uts/core/services/fcm_service.dart';
import 'package:uts/core/services/session_cleanup_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uts/features/notification/data/datasources/notification_remote_data_source.dart';
import 'package:uts/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:uts/features/notification/domain/repositories/notification_repository.dart';
import 'package:uts/features/notification/domain/usecases/notification_usecases.dart';
import 'package:uts/features/notification/domain/usecases/delete_notification_usecases.dart';
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';

Future<void> initNotificationDependencies(GetIt sl) async {
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => SupabaseNotificationRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => MarkNotificationAsRead(sl()));
  sl.registerLazySingleton(() => WatchNotifications(sl()));
  sl.registerLazySingleton(() => DeleteNotification(sl()));
  sl.registerLazySingleton(() => DeleteMultipleNotifications(sl()));
  sl.registerLazySingleton(() => DeleteAllNotifications(sl()));

  sl.registerLazySingleton(() => LocalNotificationService());
  sl.registerLazySingleton(() => FCMService(sl(), sl()));
  sl.registerLazySingleton(
    () => SessionCleanupService(
      preferences: sl(),
      fcmService: sl(),
      localNotificationService: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => NotificationBloc(
      getNotifications: sl(),
      markNotificationAsRead: sl(),
      watchNotifications: sl(),
      deleteNotification: sl(),
      deleteMultipleNotifications: sl(),
      deleteAllNotifications: sl(),
      localNotificationService: sl(),
    ),
  );
}
