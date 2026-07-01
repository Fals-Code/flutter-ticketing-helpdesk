import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/services/ticket_tracking_timeline_builder.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';

import 'ticket_tracking_event.dart';
import 'ticket_tracking_state.dart';

class TicketTrackingBloc
    extends Bloc<TicketTrackingEvent, TicketTrackingState> {
  final GetTicketDetailUseCase getTicketDetailUseCase;
  final GetTicketHistoryUseCase getTicketHistoryUseCase;
  final TicketTrackingTimelineBuilder _timelineBuilder =
      TicketTrackingTimelineBuilder();
  int _loadGeneration = 0;

  TicketTrackingBloc({
    required this.getTicketDetailUseCase,
    required this.getTicketHistoryUseCase,
  }) : super(const TicketTrackingState()) {
    on<LoadTicketTrackingRequested>(_onLoadRequested);
    on<ResetTicketTrackingState>(_onResetState);
  }

  Future<void> _onLoadRequested(
    LoadTicketTrackingRequested event,
    Emitter<TicketTrackingState> emit,
  ) async {
    _loadGeneration++;
    final generation = _loadGeneration;

    emit(
      state.copyWith(
        status: TicketTrackingStatus.loading,
        clearErrorMessage: true,
      ),
    );

    final ticketResult = await getTicketDetailUseCase(event.ticketId);
    if (generation != _loadGeneration || isClosed) {
      return;
    }
    final ticket = ticketResult.fold<TicketEntity?>(
      (failure) {
        emit(
          state.copyWith(
            status: _statusFromFailure(failure),
            errorMessage: failure.message,
            clearTicket: true,
            clearViewData: true,
          ),
        );
        return null;
      },
      (ticket) => ticket,
    );

    if (ticket == null) {
      return;
    }

    final historyResult = await getTicketHistoryUseCase(event.ticketId);
    if (generation != _loadGeneration || isClosed) {
      return;
    }

    historyResult.fold(
      (failure) => emit(
        state.copyWith(
          status: _statusFromFailure(failure),
          ticket: ticket,
          errorMessage: failure.message,
          clearViewData: true,
        ),
      ),
      (history) {
        final viewData = _timelineBuilder.build(
          ticket: ticket,
          history: history,
        );
        emit(
          state.copyWith(
            status: TicketTrackingStatus.loaded,
            ticket: ticket,
            viewData: viewData,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  void _onResetState(
    ResetTicketTrackingState event,
    Emitter<TicketTrackingState> emit,
  ) {
    _loadGeneration++;
    emit(const TicketTrackingState());
  }

  TicketTrackingStatus _statusFromFailure(Failure failure) {
    if (failure is TicketOperationFailure) {
      return switch (failure.type) {
        TicketFailureType.authorization ||
        TicketFailureType.authentication =>
          TicketTrackingStatus.unauthorized,
        TicketFailureType.notFound => TicketTrackingStatus.notFound,
        _ => TicketTrackingStatus.failure,
      };
    }

    if (failure.code == 401 || failure.code == 403) {
      return TicketTrackingStatus.unauthorized;
    }

    if (failure.code == 404) {
      return TicketTrackingStatus.notFound;
    }

    return TicketTrackingStatus.failure;
  }

  @override
  Future<void> close() async {
    _loadGeneration++;
    await super.close();
  }
}
