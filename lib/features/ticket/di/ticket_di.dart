import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uts/core/services/realtime_session_service.dart';
import 'package:uts/features/ticket/data/datasources/ticket_local_data_source.dart';
import 'package:uts/features/ticket/data/datasources/ticket_attachment_storage_data_source.dart';
import 'package:uts/features/ticket/data/datasources/ticket_remote_data_source.dart';
import 'package:uts/features/ticket/data/datasources/typed_ticket_remote_data_source.dart';
import 'package:uts/features/ticket/data/repositories/ticket_repository_impl.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/watch_ticket_detail_usecase.dart';
import 'package:uts/features/ticket/domain/usecases/watch_ticket_comments_usecase.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_bloc.dart';

Future<void> initTicketDependencies(GetIt sl) async {
  // BLoCs
  sl.registerFactory<TicketListBloc>(
    () => TicketListBloc(
      getTicketsUseCase: sl(),
      getAllTicketsUseCase: sl(),
      watchTicketsUseCase: sl(),
      createTicketUseCase: sl(),
      localDataSource: sl(),
      connectivityService: sl(),
    ),
  );

  sl.registerFactory(
    () => TicketCreateBloc(
      createTicketUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => TicketDetailBloc(
      getTicketDetailUseCase: sl(),
      getTicketCommentsUseCase: sl(),
      addCommentUseCase: sl(),
      deleteTicketUseCase: sl(),
      updateTicketStatusUseCase: sl(),
      assignTicketUseCase: sl(),
      getTicketHistoryUseCase: sl(),
      watchTicketDetailUseCase: sl(),
      watchTicketCommentsUseCase: sl(),
      submitRatingUseCase: sl(),
      localDataSource: sl(),
      connectivityService: sl(),
    ),
  );

  sl.registerFactory(
    () => TicketTrackingBloc(
      getTicketDetailUseCase: sl(),
      getTicketHistoryUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => TicketStatsBloc(
      getTicketStatsUseCase: sl(),
      getStaffUsersUseCase: sl(),
      getAllTicketHistoryUseCase: sl(),
      connectivityService: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => GetTicketsUseCase(sl()));
  sl.registerLazySingleton(() => CreateTicketUseCase(sl()));
  sl.registerLazySingleton(() => GetTicketDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetTicketCommentsUseCase(sl()));
  sl.registerLazySingleton(() => AddCommentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTicketUseCase(sl()));
  sl.registerLazySingleton(() => GetTicketStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetTicketHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetAllTicketHistoryUseCase(sl()));
  sl.registerLazySingleton(() => WatchTicketsUseCase(sl()));
  sl.registerLazySingleton(() => WatchTicketDetailUseCase(sl()));
  sl.registerLazySingleton(() => WatchTicketCommentsUseCase(sl()));
  sl.registerLazySingleton(() => SubmitRatingUseCase(sl()));

  // Admin UseCases
  sl.registerLazySingleton(() => GetAllTicketsUseCase(sl()));
  sl.registerLazySingleton(() => GetStaffUsersUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTicketStatusUseCase(sl()));
  sl.registerLazySingleton(() => AssignTicketUseCase(sl()));

  // Repository
  sl.registerLazySingleton<TicketRepository>(
    () => TicketRepositoryImpl(
      remoteDataSource: sl(),
      attachmentStorageDataSource: sl(),
    ),
  );

  // Data Sources
  if (!sl.isRegistered<SharedPreferences>()) {
    final sharedPrefs = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => sharedPrefs);
  }

  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }

  if (!sl.isRegistered<RealtimeSessionService>()) {
    sl.registerLazySingleton<RealtimeSessionService>(
      () => SupabaseRealtimeSessionService(sl<SupabaseClient>()),
    );
  }

  sl.registerLazySingleton<TicketLocalDataSource>(
    () => SharedPrefsTicketLocalDataSource(
      sl<SharedPreferences>(),
      sessionProvider: sl<TicketCacheSessionProvider>(),
    ),
  );

  sl.registerLazySingleton<TicketCacheSessionProvider>(
    () => SupabaseTicketCacheSessionProvider(sl<SupabaseClient>()),
  );

  sl.registerLazySingleton<TicketRemoteDataSource>(
    () => TypedSupabaseTicketRemoteDataSourceImpl(
      sl<SupabaseClient>(),
      realtimeSessionService: sl<RealtimeSessionService>(),
    ),
  );

  sl.registerLazySingleton<TicketAttachmentStorageDataSource>(
    () => SupabaseTicketAttachmentStorageDataSource(sl<SupabaseClient>()),
  );
}
