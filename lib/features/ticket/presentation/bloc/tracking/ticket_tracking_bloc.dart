import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_tracking_item.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';

import 'ticket_tracking_event.dart';
import 'ticket_tracking_state.dart';

class TicketTrackingBloc
    extends Bloc<TicketTrackingEvent, TicketTrackingState> {
  final GetTicketDetailUseCase getTicketDetailUseCase;
  final GetTicketHistoryUseCase getTicketHistoryUseCase;

  TicketTrackingBloc({
    required this.getTicketDetailUseCase,
    required this.getTicketHistoryUseCase,
  }) : super(const TicketTrackingState()) {
    on<LoadTicketTrackingRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    LoadTicketTrackingRequested event,
    Emitter<TicketTrackingState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TicketTrackingStatus.loading,
        clearErrorMessage: true,
      ),
    );

    final ticketResult = await getTicketDetailUseCase(event.ticketId);
    final ticket = ticketResult.fold<TicketEntity?>(
      (failure) {
        emit(
          state.copyWith(
            status: _statusFromFailure(failure),
            errorMessage: failure.message,
            clearTicket: true,
            items: const [],
          ),
        );
        return null;
      },
      (ticket) => ticket,
    );

    if (ticket == null) {
      return;
    }
    emit(state.copyWith(ticket: ticket, clearErrorMessage: true));

    final historyResult = await getTicketHistoryUseCase(event.ticketId);
    historyResult.fold(
      (failure) => emit(
        state.copyWith(
          status: _statusFromFailure(failure),
          ticket: ticket,
          errorMessage: failure.message,
          items: const [],
        ),
      ),
      (history) {
        final items = _mapTrackingItems(history);
        emit(
          state.copyWith(
            status: items.isEmpty
                ? TicketTrackingStatus.empty
                : TicketTrackingStatus.loaded,
            ticket: ticket,
            items: items,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  List<TicketTrackingItem> _mapTrackingItems(
      List<TicketHistoryEntity> history) {
    final sorted = [...history]..sort((left, right) {
        final byTime = left.createdAt.compareTo(right.createdAt);
        if (byTime != 0) {
          return byTime;
        }
        return left.id.compareTo(right.id);
      });

    return List<TicketTrackingItem>.generate(sorted.length, (index) {
      final mapped = TicketTrackingItem.fromHistory(sorted[index]);
      final isCurrent = index == sorted.length - 1;
      return TicketTrackingItem(
        id: mapped.id,
        ticketId: mapped.ticketId,
        title: mapped.title,
        description: mapped.description,
        actorName: mapped.actorName,
        occurredAt: mapped.occurredAt,
        oldStatus: mapped.oldStatus,
        newStatus: mapped.newStatus,
        type: mapped.type,
        isCompleted: true,
        isCurrent: isCurrent,
      );
    });
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
}
