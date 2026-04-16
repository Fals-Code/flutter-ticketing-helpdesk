import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'ticket_list_event.dart';
import 'ticket_list_state.dart';

class TicketListBloc extends Bloc<TicketListEvent, TicketListState> {
  final GetTicketsUseCase getTicketsUseCase;
  final GetAllTicketsUseCase getAllTicketsUseCase;
  final WatchTicketsUseCase watchTicketsUseCase;
  final CreateTicketUseCase createTicketUseCase;
  StreamSubscription? _ticketSubscription;

  TicketListBloc({
    required this.getTicketsUseCase,
    required this.getAllTicketsUseCase,
    required this.watchTicketsUseCase,
    required this.createTicketUseCase,
  }) : super(const TicketListState()) {
    on<FetchTicketsRequested>(_onFetchTickets);
    on<FetchAllTicketsRequested>(_onFetchAllTickets);
    on<SearchTicketsRequested>(_onSearchQueryChanged);
    on<FilterStatusChanged>(_onFilterStatusChanged);
    on<FilterCategoryChanged>(_onFilterCategoryChanged);
    on<StartTicketListSubscription>(_onStartSubscription);
    on<CreateTicketRequested>(_onCreateTicket);
    on<ResetTicketListState>(_onResetState);
  }

  Future<void> _onCreateTicket(
    CreateTicketRequested event,
    Emitter<TicketListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await createTicketUseCase(CreateTicketParams(
      userId: event.userId,
      title: event.title,
      description: event.description,
      category: event.category,
      priority: event.priority,
      imagePaths: event.imagePaths,
    ));

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (ticket) => emit(state.copyWith(
        isLoading: false,
        successMessage: 'Laporan berhasil dibuat',
      )),
    );
  }

  void _onStartSubscription(
    StartTicketListSubscription event,
    Emitter<TicketListState> emit,
  ) {
    _ticketSubscription?.cancel();
    _ticketSubscription = watchTicketsUseCase(
      userId: event.userId,
      assignedToId: event.assignedToId,
    ).listen(
      (tickets) {
        final filteredTickets = _applyFilters(tickets);
        emit(state.copyWith(tickets: filteredTickets));
      },
    );
  }

  Future<void> _onFetchTickets(
    FetchTicketsRequested event,
    Emitter<TicketListState> emit,
  ) async {
    if (event.page == 0) {
      emit(state.copyWith(isLoading: true, tickets: []));
    }

    final result = await getTicketsUseCase(
      GetTicketsParams(
        page: event.page,
        limit: event.limit,
        searchQuery: state.searchQuery,
        category: state.categoryFilter,
        status: state.statusFilter == TicketStatusFilter.all 
            ? null 
            : _mapStatusFilter(state.statusFilter),
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (newTickets) {
        final allTickets = event.page == 0 ? newTickets : [...state.tickets, ...newTickets];
        emit(state.copyWith(
          isLoading: false,
          tickets: allTickets,
          isLastPage: newTickets.length < event.limit,
        ));
      },
    );
  }

  Future<void> _onFetchAllTickets(
    FetchAllTicketsRequested event,
    Emitter<TicketListState> emit,
  ) async {
    if (event.page == 0) {
      emit(state.copyWith(isLoading: true, allTickets: []));
    }

    final result = await getAllTicketsUseCase(
      GetTicketsParams(
        page: event.page,
        limit: event.limit,
        status: state.statusFilter == TicketStatusFilter.all 
            ? null 
            : _mapStatusFilter(state.statusFilter),
        searchQuery: state.searchQuery,
        category: state.categoryFilter,
        assignedToId: event.assignedToId,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (newTickets) {
        final currentTickets = event.page == 0 ? newTickets : [...state.allTickets, ...newTickets];
        emit(state.copyWith(
          isLoading: false,
          allTickets: currentTickets,
          isLastPageAll: newTickets.length < event.limit,
        ));
      },
    );
  }

  Future<void> _onSearchQueryChanged(
    SearchTicketsRequested event,
    Emitter<TicketListState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    add(const FetchTicketsRequested(page: 0));
    add(const FetchAllTicketsRequested(page: 0));
  }

  Future<void> _onFilterStatusChanged(
    FilterStatusChanged event,
    Emitter<TicketListState> emit,
  ) async {
    emit(state.copyWith(statusFilter: event.filter));
    add(const FetchTicketsRequested(page: 0));
    add(const FetchAllTicketsRequested(page: 0));
  }

  Future<void> _onFilterCategoryChanged(
    FilterCategoryChanged event,
    Emitter<TicketListState> emit,
  ) async {
    emit(state.copyWith(categoryFilter: event.category));
    add(const FetchTicketsRequested(page: 0));
    add(const FetchAllTicketsRequested(page: 0));
  }

  void _onResetState(ResetTicketListState event, Emitter<TicketListState> emit) {
    _ticketSubscription?.cancel();
    emit(const TicketListState());
  }

  @override
  Future<void> close() {
    _ticketSubscription?.cancel();
    return super.close();
  }

  List<TicketEntity> _applyFilters(List<TicketEntity> tickets) {
    return tickets.where((ticket) {
      if (state.statusFilter != TicketStatusFilter.all) {
        final mappedStatus = _mapStatusFilter(state.statusFilter);
        final ticketStatusName = ticket.status.name.toLowerCase();
        if (mappedStatus.contains(',')) {
          final allowed = mappedStatus.split(',');
          if (!allowed.contains(ticketStatusName)) return false;
        } else {
          if (ticketStatusName != mappedStatus) return false;
        }
      }
      if (state.categoryFilter != null && state.categoryFilter != 'General') {
        if (ticket.category != state.categoryFilter) return false;
      }
      final query = state.searchQuery.toLowerCase();
      if (query.isNotEmpty) {
        if (!ticket.title.toLowerCase().contains(query) && !ticket.description.toLowerCase().contains(query)) return false;
      }
      return true;
    }).toList();
  }

  String _mapStatusFilter(TicketStatusFilter filter) {
    switch (filter) {
      case TicketStatusFilter.open: return 'open';
      case TicketStatusFilter.inProgress: return 'in_progress';
      case TicketStatusFilter.resolved: return 'resolved';
      case TicketStatusFilter.closed: return 'closed';
      case TicketStatusFilter.all: return 'all';
    }
  }
}
