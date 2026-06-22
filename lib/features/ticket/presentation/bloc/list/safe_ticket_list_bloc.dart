import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/services/connectivity_service.dart';
import 'package:uts/features/ticket/data/datasources/ticket_local_data_source.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';

import 'ticket_list_bloc.dart';
import 'ticket_list_event.dart';
import 'ticket_list_state.dart';

/// Ticket list BLoC variant that converts realtime stream callbacks into BLoC
/// events before emitting state.
///
/// Calling `emit` directly from `Stream.listen` after the original event
/// handler has returned violates BLoC's emitter lifecycle and throws
/// `emit was called after an event handler completed normally`.
class SafeTicketListBloc extends TicketListBloc {
  StreamSubscription<List<TicketEntity>>? _safeTicketSubscription;

  SafeTicketListBloc({
    required GetTicketsUseCase getTicketsUseCase,
    required GetAllTicketsUseCase getAllTicketsUseCase,
    required WatchTicketsUseCase watchTicketsUseCase,
    required CreateTicketUseCase createTicketUseCase,
    required TicketLocalDataSource localDataSource,
    required ConnectivityService connectivityService,
  }) : super(
          getTicketsUseCase: getTicketsUseCase,
          getAllTicketsUseCase: getAllTicketsUseCase,
          watchTicketsUseCase: watchTicketsUseCase,
          createTicketUseCase: createTicketUseCase,
          localDataSource: localDataSource,
          connectivityService: connectivityService,
        ) {
    on<_RealtimeTicketsArrived>(_onRealtimeTicketsArrived);
    on<_RealtimeTicketsFailed>(_onRealtimeTicketsFailed);
  }

  @override
  void add(TicketListEvent event) {
    if (event is StartTicketListSubscription) {
      unawaited(_startSafeSubscription(event));
      return;
    }

    if (event is ResetTicketListState) {
      final subscription = _safeTicketSubscription;
      _safeTicketSubscription = null;
      if (subscription != null) {
        unawaited(subscription.cancel());
      }
    }

    super.add(event);
  }

  Future<void> _startSafeSubscription(
    StartTicketListSubscription event,
  ) async {
    await _safeTicketSubscription?.cancel();

    if (isClosed) {
      return;
    }

    _safeTicketSubscription = watchTicketsUseCase(
      userId: event.userId,
      assignedToId: event.assignedToId,
    ).listen(
      (tickets) {
        if (!isClosed) {
          super.add(
            _RealtimeTicketsArrived(
              tickets: tickets,
              isStaff: event.isStaff,
            ),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed) {
          super.add(_RealtimeTicketsFailed(error.toString()));
        }
      },
    );
  }

  void _onRealtimeTicketsArrived(
    _RealtimeTicketsArrived event,
    Emitter<TicketListState> emit,
  ) {
    final filteredTickets = _applyRealtimeFilters(event.tickets);

    if (event.isStaff) {
      emit(state.copyWith(allTickets: filteredTickets));
    } else {
      emit(state.copyWith(tickets: filteredTickets));
    }
  }

  void _onRealtimeTicketsFailed(
    _RealtimeTicketsFailed event,
    Emitter<TicketListState> emit,
  ) {
    emit(
      state.copyWith(
        errorMessage: 'Realtime tiket terputus: ${event.message}',
      ),
    );
  }

  List<TicketEntity> _applyRealtimeFilters(List<TicketEntity> tickets) {
    return tickets.where((ticket) {
      if (state.statusFilter != TicketStatusFilter.all) {
        final mappedStatus = _mapStatusFilter(state.statusFilter);
        final ticketStatusName = ticket.status.name.toLowerCase();

        if (mappedStatus.contains(',')) {
          final allowed = mappedStatus.split(',');
          if (!allowed.contains(ticketStatusName)) {
            return false;
          }
        } else if (ticketStatusName != mappedStatus) {
          return false;
        }
      }

      final query = state.searchQuery.toLowerCase();
      if (query.isNotEmpty &&
          !ticket.title.toLowerCase().contains(query) &&
          !ticket.description.toLowerCase().contains(query)) {
        return false;
      }

      if (state.assignedToId != null &&
          ticket.assignedTo != state.assignedToId) {
        return false;
      }

      return true;
    }).toList(growable: false);
  }

  String _mapStatusFilter(TicketStatusFilter filter) {
    switch (filter) {
      case TicketStatusFilter.open:
        return 'open';
      case TicketStatusFilter.pending:
        return 'pending';
      case TicketStatusFilter.inProgress:
        return 'in_progress';
      case TicketStatusFilter.resolved:
        return 'resolved';
      case TicketStatusFilter.closed:
        return 'closed';
      case TicketStatusFilter.reopened:
        return 'reopened';
      case TicketStatusFilter.all:
        return 'all';
    }
  }

  @override
  Future<void> close() async {
    await _safeTicketSubscription?.cancel();
    return super.close();
  }
}

class _RealtimeTicketsArrived extends TicketListEvent {
  final List<TicketEntity> tickets;
  final bool isStaff;

  const _RealtimeTicketsArrived({
    required this.tickets,
    required this.isStaff,
  });

  @override
  List<Object?> get props => [tickets, isStaff];
}

class _RealtimeTicketsFailed extends TicketListEvent {
  final String message;

  const _RealtimeTicketsFailed(this.message);

  @override
  List<Object?> get props => [message];
}
