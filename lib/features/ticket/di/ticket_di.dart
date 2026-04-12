import 'package:get_it/get_it.dart';
import '../data/datasources/ticket_remote_data_source.dart';
import '../data/repositories/ticket_repository_impl.dart';
import '../domain/repositories/ticket_repository.dart';
import '../domain/usecases/ticket_usecases.dart';
import '../domain/usecases/ticket_admin_usecases.dart';
import '../domain/usecases/activity_usecases.dart';
import '../presentation/bloc/ticket_bloc.dart';

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
  sl.registerLazySingleton<TicketRemoteDataSource>(
    () => SupabaseTicketRemoteDataSourceImpl(sl<sup.SupabaseClient>()),
  );
}
