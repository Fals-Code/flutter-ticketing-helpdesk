import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ticket_q/core/constants/enums.dart';
import 'package:ticket_q/features/ticket/domain/entities/ticket_entity.dart';

import 'ticket_list_bloc.dart';
import 'ticket_list_event.dart';
import 'ticket_list_state.dart';

class SafeTicketListBloc extends TicketListBloc {
  StreamSubscription<List<TicketEntity>>? _safeTicketSubscription;
  int _generation = 0;

  SafeTicketListBloc({
    required super.getTicketsUseCase,
    required super.getAllTicketsUseCase,
    required super.watchTicketsUseCase,
    required super.createTicketUseCase,
    required super.localDataSource,
    required super.connectivityService,
  }) {
    on<_RealtimeTicketsArrived>(_onRealtimeTicketsArrived);
    on<_RealtimeTicketsFailed>(_onRealtimeTicketsFailed);
  }

  @override
  void add(TicketListEvent event) {
    if (event is StartTicketListSubscription) {
      final generation = ++_generation;
      unawaited(_startSubscription(event, generation));
      return;
    }
    if (event is ResetTicketListState) {
      final generation = ++_generation;
      unawaited(_resetSubscription(event, generation));
      return;
    }
    super.add(event);
  }

  Future<void> _startSubscription(
    StartTicketListSubscription event,
    int generation,
  ) async {
    final previous = _safeTicketSubscription;
    _safeTicketSubscription = null;
    await previous?.cancel();
    if (isClosed || generation != _generation) return;

    _safeTicketSubscription = watchTicketsUseCase(
      userId: event.userId,
      assignedToId: event.assignedToId,
    ).listen(
      (tickets) {
        if (!isClosed && generation == _generation) {
          super.add(
            _RealtimeTicketsArrived(
              tickets: tickets,
              isStaff: event.isStaff,
            ),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed && generation == _generation) {
          super.add(_RealtimeTicketsFailed(error.toString()));
        }
      },
    );
  }

  Future<void> _resetSubscription(
    ResetTicketListState event,
    int generation,
  ) async {
    final previous = _safeTicketSubscription;
    _safeTicketSubscription = null;
    await previous?.cancel();
    if (!isClosed && generation == _generation) {
      super.add(event);
    }
  }

  void _onRealtimeTicketsArrived(
    _RealtimeTicketsArrived event,
    Emitter<TicketListState> emit,
  ) {
    final tickets = _filter(event.tickets);
    emit(
      event.isStaff
          ? state.copyWith(allTickets: tickets)
          : state.copyWith(tickets: tickets),
    );
  }

  void _onRealtimeTicketsFailed(
    _RealtimeTicketsFailed event,
    Emitter<TicketListState> emit,
  ) {
    emit(state.copyWith(
        errorMessage: 'Realtime tiket terputus: ${event.message}'));
  }

  List<TicketEntity> _filter(List<TicketEntity> tickets) {
    return tickets.where((ticket) {
      if (state.statusFilter != TicketStatusFilter.all) {
        final status = _statusValue(state.statusFilter);
        if (ticket.status.name.toLowerCase() != status) return false;
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

  String _statusValue(TicketStatusFilter filter) {
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
    _generation++;
    final subscription = _safeTicketSubscription;
    _safeTicketSubscription = null;
    await subscription?.cancel();
    await super.close();
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
