import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/core/usecases/usecase.dart';
import 'ticket_stats_event.dart';
import 'ticket_stats_state.dart';

class TicketStatsBloc extends Bloc<TicketStatsEvent, TicketStatsState> {
  final GetTicketStatsUseCase getTicketStatsUseCase;
  final GetStaffUsersUseCase getStaffUsersUseCase;
  final GetAllTicketHistoryUseCase getAllTicketHistoryUseCase;

  TicketStatsBloc({
    required this.getTicketStatsUseCase,
    required this.getStaffUsersUseCase,
    required this.getAllTicketHistoryUseCase,
  }) : super(const TicketStatsState()) {
    on<FetchTicketStatsRequested>(_onFetchStats);
    on<FetchStaffUsersRequested>(_onFetchStaffUsers);
    on<FetchAllHistoryRequested>(_onFetchAllHistory);
    on<ResetTicketStatsState>(_onResetState);
  }

  Future<void> _onFetchStats(FetchTicketStatsRequested event, Emitter<TicketStatsState> emit) async {
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
    emit(state.copyWith(isLoading: true));
    final result = await getAllTicketHistoryUseCase(event.changedBy);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (history) => emit(state.copyWith(isLoading: false, history: history)),
    );
  }

  void _onResetState(ResetTicketStatsState event, Emitter<TicketStatsState> emit) {
    emit(const TicketStatsState());
  }
}
