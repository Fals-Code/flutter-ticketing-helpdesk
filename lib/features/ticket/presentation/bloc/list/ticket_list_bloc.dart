import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/core/constants/enums.dart';
import 'ticket_list_event.dart';
import 'ticket_list_state.dart';
import 'package:uts/features/ticket/data/datasources/ticket_local_data_source.dart';
import 'package:uts/features/ticket/data/models/ticket_model.dart';

class TicketListBloc extends Bloc<TicketListEvent, TicketListState> {
  final GetTicketsUseCase getTicketsUseCase;
  final GetAllTicketsUseCase getAllTicketsUseCase;
  final WatchTicketsUseCase watchTicketsUseCase;
  final CreateTicketUseCase createTicketUseCase;
  final TicketLocalDataSource localDataSource;
  StreamSubscription? _ticketSubscription;

  TicketListBloc({
    required this.getTicketsUseCase,
    required this.getAllTicketsUseCase,
    required this.watchTicketsUseCase,
    required this.createTicketUseCase,
    required this.localDataSource,
  }) : super(const TicketListState()) {
    on<FetchTicketsRequested>(_onFetchTickets);
    on<FetchAllTicketsRequested>(_onFetchAllTickets);
    on<SearchTicketsRequested>(_onSearchQueryChanged);
    on<FilterStatusChanged>(_onFilterStatusChanged);
    on<StartTicketListSubscription>(_onStartSubscription);
    on<CreateTicketRequested>(_onCreateTicket);
    on<ResetTicketListState>(_onResetState);
  }

  Future<void> _onCreateTicket(
    CreateTicketRequested event,
    Emitter<TicketListState> emit,
  ) async {
    // 0. Hardened Validation
    if (event.category.isEmpty) {
      emit(state.copyWith(errorMessage: 'Kategori harus dipilih'));
      return;
    }

    if (event.title.trim().length < 5) {
      emit(state.copyWith(errorMessage: 'Judul terlalu pendek'));
      return;
    }

    // 1. Create optimistic ticket
    final optimisticTicket = TicketEntity(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: event.title,
      description: event.description,
      status: TicketStatus.open,
      category: event.category,
      createdAt: DateTime.now(),
      userId: event.userId,
      imageUrls: event.imagePaths,
    );

    // 2. Insert into current list (optimistic update)
    final originalTickets = [...state.tickets];
    final updatedTickets = [optimisticTicket, ...originalTickets];

    emit(state.copyWith(
      tickets: updatedTickets,
      successMessage: null, // Clear messages
      errorMessage: null,
    ));

    final result = await createTicketUseCase(CreateTicketParams(
      userId: event.userId,
      title: event.title,
      description: event.description,
      category: event.category,
      imagePaths: event.imagePaths,
    ));

    result.fold(
      (failure) {
        // 3. Rollback on failure
        emit(state.copyWith(
          tickets: originalTickets,
          errorMessage: failure.message,
        ));
      },
      (ticket) {
        // 4. Success
        emit(state.copyWith(
          successMessage: 'Laporan berhasil dibuat',
          errorMessage: null,
        ));
      },
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
        if (event.isStaff) {
          emit(state.copyWith(allTickets: filteredTickets));
        } else {
          emit(state.copyWith(tickets: filteredTickets));
        }
      },
    );
  }

  Future<void> _onFetchTickets(
    FetchTicketsRequested event,
    Emitter<TicketListState> emit,
  ) async {
    final bool isInitial = event.page == 0;

    if (isInitial) {
      emit(state.copyWith(
          isLoading: true,
          tickets: [],
          currentPage: 0,
          isLastPage: false,
          errorMessage: null));
    } else {
      emit(state.copyWith(isLoading: true, errorMessage: null));
    }

    final result = await getTicketsUseCase(
      GetTicketsParams(
        page: event.page,
        limit: event.limit,
        searchQuery: state.searchQuery,
        status: state.statusFilter == TicketStatusFilter.all
            ? null
            : _mapStatusFilter(state.statusFilter),
      ),
    );

    result.fold(
      (failure) async {
        if (isInitial) {
          try {
            final cached = await localDataSource.getCachedTickets();
            emit(state.copyWith(
              isLoading: false,
              tickets: cached.map((m) => m.toEntity()).toList(),
              isOffline: true,
              currentPage: 0,
            ));
            return;
          } catch (_) {}
        }
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      },
      (newTickets) {
        if (isInitial) {
          localDataSource.cacheTickets(
              newTickets.map((t) => TicketModel.fromEntity(t)).toList());
        }

        final allTickets =
            isInitial ? newTickets : [...state.tickets, ...newTickets];
        emit(state.copyWith(
          isLoading: false,
          tickets: allTickets,
          isLastPage: newTickets.length < event.limit,
          isOffline: false,
          currentPage: event.page, // Update page only on success
        ));
      },
    );
  }

  Future<void> _onFetchAllTickets(
    FetchAllTicketsRequested event,
    Emitter<TicketListState> emit,
  ) async {
    final bool isInitial = event.page == 0;

    final assignedToId = event.assignedToId ?? state.assignedToId;

    if (isInitial) {
      emit(state.copyWith(
          isLoading: true,
          allTickets: [],
          allTicketsPage: 0,
          isLastPageAll: false,
          errorMessage: null,
          assignedToId: assignedToId));
    } else {
      emit(state.copyWith(
          isLoading: true, errorMessage: null, assignedToId: assignedToId));
    }

    final result = await getAllTicketsUseCase(
      GetTicketsParams(
        page: event.page,
        limit: event.limit,
        status: state.statusFilter == TicketStatusFilter.all
            ? null
            : _mapStatusFilter(state.statusFilter),
        searchQuery: state.searchQuery,
        assignedToId: assignedToId,
      ),
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (newTickets) {
        final currentTickets =
            isInitial ? newTickets : [...state.allTickets, ...newTickets];
        emit(state.copyWith(
          isLoading: false,
          allTickets: currentTickets,
          isLastPageAll: newTickets.length < event.limit,
          allTicketsPage: event.page, // Update page only on success
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

  void _onResetState(
      ResetTicketListState event, Emitter<TicketListState> emit) {
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
      final query = state.searchQuery.toLowerCase();
      if (query.isNotEmpty) {
        if (!ticket.title.toLowerCase().contains(query) &&
            !ticket.description.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (state.assignedToId != null) {
        if (ticket.assignedTo != state.assignedToId) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String _mapStatusFilter(TicketStatusFilter filter) {
    switch (filter) {
      case TicketStatusFilter.open:
        return 'open';
      case TicketStatusFilter.inProgress:
        return 'in_progress';
      case TicketStatusFilter.resolved:
        return 'resolved';
      case TicketStatusFilter.closed:
        return 'closed';
      case TicketStatusFilter.all:
        return 'all';
    }
  }
}
