import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/core/usecases/usecase.dart';
import 'ticket_stats_event.dart';
import 'ticket_stats_state.dart';

import 'package:uts/core/services/connectivity_service.dart';

class TicketStatsBloc extends Bloc<TicketStatsEvent, TicketStatsState> {
  final GetTicketStatsUseCase getTicketStatsUseCase;
  final GetStaffUsersUseCase getStaffUsersUseCase;
  final GetAllTicketHistoryUseCase getAllTicketHistoryUseCase;
  final ConnectivityService connectivityService;
  StreamSubscription? _connectivitySubscription;

  TicketStatsBloc({
    required this.getTicketStatsUseCase,
    required this.getStaffUsersUseCase,
    required this.getAllTicketHistoryUseCase,
    required this.connectivityService,
  }) : super(const TicketStatsState()) {
    on<FetchTicketStatsRequested>(_onFetchStats);
    on<FetchStaffUsersRequested>(_onFetchStaffUsers);
    on<FetchAllHistoryRequested>(_onFetchAllHistory);
    on<ResetTicketStatsState>(_onResetState);

    _connectivitySubscription = connectivityService.connectionStream.listen((status) {
      if (status == ConnectionStatus.online) {
        add(FetchTicketStatsRequested(assignedToId: state.assignedToId));
        add(const FetchStaffUsersRequested());
        if (state.history.isNotEmpty) {
           add(FetchAllHistoryRequested(
            changedBy: null, 
            startDate: state.startDate,
            endDate: state.endDate,
          ));
        }
      }
    });
  }

  Future<void> _onFetchStats(FetchTicketStatsRequested event, Emitter<TicketStatsState> emit) async {
    emit(state.copyWith(assignedToId: event.assignedToId));
    final result = await getTicketStatsUseCase(event.assignedToId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (stats) => emit(state.copyWith(stats: stats)),
    );
  }

  Future<void> _onFetchStaffUsers(FetchStaffUsersRequested event, Emitter<TicketStatsState> emit) async {
    final result = await getStaffUsersUseCase(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (users) => emit(state.copyWith(staffUsers: users)),
    );
  }

  Future<void> _onFetchAllHistory(FetchAllHistoryRequested event, Emitter<TicketStatsState> emit) async {
    emit(state.copyWith(isLoading: true, startDate: event.startDate, endDate: event.endDate));
    final result = await getAllTicketHistoryUseCase(GetHistoryParams(
      changedBy: event.changedBy,
      startDate: event.startDate,
      endDate: event.endDate,
    ));
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (history) => emit(state.copyWith(isLoading: false, history: history)),
    );
  }

  void _onResetState(ResetTicketStatsState event, Emitter<TicketStatsState> emit) {
    emit(const TicketStatsState());
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
