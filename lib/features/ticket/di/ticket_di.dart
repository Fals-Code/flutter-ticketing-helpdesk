import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts/features/ticket/data/datasources/ticket_local_data_source.dart';
import 'package:uts/features/ticket/data/datasources/ticket_remote_data_source.dart';
import 'package:uts/features/ticket/data/repositories/ticket_repository_impl.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/watch_ticket_comments_usecase.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';

Future<void> initTicketDependencies(GetIt sl) async {
  // BLoCs
  sl.registerFactory(() => TicketListBloc(
        getTicketsUseCase: sl(),
        getAllTicketsUseCase: sl(),
        watchTicketsUseCase: sl(),
        createTicketUseCase: sl(),
        localDataSource: sl(),
      ));

  sl.registerFactory(() => TicketDetailBloc(
        getTicketDetailUseCase: sl(),
        getTicketCommentsUseCase: sl(),
        addCommentUseCase: sl(),
        updateTicketStatusUseCase: sl(),
        assignTicketUseCase: sl(),
        getTicketHistoryUseCase: sl(),
        watchTicketCommentsUseCase: sl(),
        submitRatingUseCase: sl(),
      ));

  sl.registerFactory(() => TicketStatsBloc(
        getTicketStatsUseCase: sl(),
        getStaffUsersUseCase: sl(),
        getAllTicketHistoryUseCase: sl(),
      ));

  // UseCases
  sl.registerLazySingleton(() => GetTicketsUseCase(sl()));
  sl.registerLazySingleton(() => CreateTicketUseCase(sl()));
  sl.registerLazySingleton(() => GetTicketDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetTicketCommentsUseCase(sl()));
  sl.registerLazySingleton(() => AddCommentUseCase(sl()));
  sl.registerLazySingleton(() => GetTicketStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetTicketHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetAllTicketHistoryUseCase(sl()));
  sl.registerLazySingleton(() => WatchTicketsUseCase(sl()));
  sl.registerLazySingleton(() => WatchTicketCommentsUseCase(sl()));
  sl.registerLazySingleton(() => SubmitRatingUseCase(sl()));
  
  // Admin UseCases
  sl.registerLazySingleton(() => GetAllTicketsUseCase(sl()));
  sl.registerLazySingleton(() => GetStaffUsersUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTicketStatusUseCase(sl()));
  sl.registerLazySingleton(() => AssignTicketUseCase(sl()));

  // Repository
  sl.registerLazySingleton<TicketRepository>(
    () => TicketRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  if (!sl.isRegistered<SharedPreferences>()) {
    final sharedPrefs = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => sharedPrefs);
  }

  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }

  sl.registerLazySingleton<TicketLocalDataSource>(
    () => SharedPrefsTicketLocalDataSource(sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<TicketRemoteDataSource>(
    () => SupabaseTicketRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
}
