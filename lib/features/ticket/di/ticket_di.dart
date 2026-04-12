import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uts/features/ticket/data/datasources/ticket_remote_data_source.dart';
import 'package:uts/features/ticket/data/repositories/ticket_repository_impl.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';

Future<void> initTicketDependencies(GetIt sl) async {
  // BLoC
  sl.registerLazySingleton(() => TicketBloc(
        getTicketsUseCase: sl(),
        createTicketUseCase: sl(),
        getTicketDetailUseCase: sl(),
        getTicketCommentsUseCase: sl(),
        addCommentUseCase: sl(),
        getAllTicketsUseCase: sl(),
        getStaffUsersUseCase: sl(),
        updateTicketStatusUseCase: sl(),
        assignTicketUseCase: sl(),
        getTicketHistoryUseCase: sl(),
        getAllTicketHistoryUseCase: sl(),
        getTicketStatsUseCase: sl(),
        watchTicketsUseCase: sl(),
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
  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }

  sl.registerLazySingleton<TicketRemoteDataSource>(
    () => SupabaseTicketRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
}
