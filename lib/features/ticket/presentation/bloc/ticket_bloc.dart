import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/usecases/usecase.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'ticket_event.dart';
import 'ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final GetTicketsUseCase getTicketsUseCase;
  final CreateTicketUseCase createTicketUseCase;
  final GetTicketDetailUseCase getTicketDetailUseCase;
  final GetTicketCommentsUseCase getTicketCommentsUseCase;
  final AddCommentUseCase addCommentUseCase;
  final GetAllTicketsUseCase getAllTicketsUseCase;
  final GetStaffUsersUseCase getStaffUsersUseCase;
  final UpdateTicketStatusUseCase updateTicketStatusUseCase;
  final AssignTicketUseCase assignTicketUseCase;
  final GetTicketHistoryUseCase getTicketHistoryUseCase;
  final GetTicketStatsUseCase getTicketStatsUseCase;
  final WatchTicketsUseCase watchTicketsUseCase;
  StreamSubscription? _ticketSubscription;

  TicketBloc({
    required this.getTicketsUseCase,
    required this.createTicketUseCase,
    required this.getTicketDetailUseCase,
    required this.getTicketCommentsUseCase,
    required this.addCommentUseCase,
    required this.getAllTicketsUseCase,
    required this.getStaffUsersUseCase,
    required this.updateTicketStatusUseCase,
    required this.assignTicketUseCase,
    required this.getTicketHistoryUseCase,
    required this.getTicketStatsUseCase,
    required this.watchTicketsUseCase,
  }) : super(const TicketState()) {
    on<FetchTicketsRequested>(_onFetchTickets);
    on<FetchAllTicketsRequested>(_onFetchAllTickets);
    on<FetchStaffUsersRequested>(_onFetchStaffUsers);
    on<CreateTicketRequested>(_onCreateTicket);
    on<FetchTicketDetailRequested>(_onFetchTicketDetail);
    on<UpdateTicketStatusRequested>(_onUpdateStatus);
    on<AssignTicketRequested>(_onAssignTicket);
    on<AddCommentRequested>(_onAddComment);
    on<FetchTicketActivitiesRequested>(_onFetchActivities);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<FilterStatusChanged>(_onFilterStatusChanged);
    on<FilterCategoryChanged>(_onFilterCategoryChanged);
    on<StartTicketSubscription>(_onStartSubscription);
    on<TicketStreamUpdated>(_onStreamUpdated);
  }

  void _onStartSubscription(
    StartTicketSubscription event,
    Emitter<TicketState> emit,
  ) {
    _ticketSubscription?.cancel();
    _ticketSubscription = watchTicketsUseCase().listen(
      (tickets) => add(TicketStreamUpdated(tickets)),
    );
  }

  void _onStreamUpdated(
    TicketStreamUpdated event,
    Emitter<TicketState> emit,
  ) {
    // Sync realtime updates with current list (optional: depends on how stream is filtered)
    // For simplicity, we can refresh stats or update specific items
    emit(state.copyWith(tickets: event.tickets));
  }

  @override
  Future<void> close() {
    _ticketSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFetchTickets(
    FetchTicketsRequested event,
    Emitter<TicketState> emit,
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
        status: state.statusFilter == TicketStatusFilter.all ? null : state.statusFilter.name,
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

  Future<void> _onCreateTicket(
    CreateTicketRequested event,
    Emitter<TicketState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await createTicketUseCase(
      CreateTicketParams(
        title: event.title,
        description: event.description,
        category: event.category,
        priority: event.priority,
        imagePaths: event.imagePaths,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (ticket) => emit(state.copyWith(
        isLoading: false,
        successMessage: 'Tiket berhasil dibuat',
      )),
    );
  }

  Future<void> _onFetchTicketDetail(
    FetchTicketDetailRequested event,
    Emitter<TicketState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, comments: []));

    final detailResult = await getTicketDetailUseCase(event.ticketId);
    final commentsResult = await getTicketCommentsUseCase(event.ticketId);

    detailResult.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (ticket) {
        commentsResult.fold(
          (failure) => emit(state.copyWith(
            isLoading: false,
            selectedTicket: ticket,
            errorMessage: failure.message,
          )),
          (comments) => emit(state.copyWith(
            isLoading: false,
            selectedTicket: ticket,
            comments: comments,
          )),
        );
      },
    );
  }

  Future<void> _onAddComment(
    AddCommentRequested event,
    Emitter<TicketState> emit,
  ) async {
    final result = await addCommentUseCase(
      AddCommentParams(ticketId: event.ticketId, message: event.message),
    );

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (comment) => emit(state.copyWith(
        comments: [...state.comments, comment],
        successMessage: 'Tanggapan berhasil dikirim',
      )),
    );
  }

  Future<void> _onFetchAllTickets(
    FetchAllTicketsRequested event,
    Emitter<TicketState> emit,
  ) async {
    if (event.page == 0) {
      emit(state.copyWith(isLoading: true, allTickets: []));
    }

    final result = await getAllTicketsUseCase(
      GetTicketsParams(
        page: event.page,
        limit: event.limit,
        status: state.statusFilter == TicketStatusFilter.all ? null : state.statusFilter.name,
        searchQuery: state.searchQuery,
        category: state.categoryFilter,
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

  Future<void> _onFetchStaffUsers(
    FetchStaffUsersRequested event,
    Emitter<TicketState> emit,
  ) async {
    final result = await getStaffUsersUseCase(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (users) => emit(state.copyWith(staffUsers: users)),
    );
  }

  Future<void> _onUpdateStatus(
    UpdateTicketStatusRequested event,
    Emitter<TicketState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await updateTicketStatusUseCase(
      UpdateStatusParams(ticketId: event.ticketId, status: event.status),
    );
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (ticket) => emit(state.copyWith(
        isLoading: false,
        selectedTicket: ticket,
        successMessage: 'Status tiket diperbarui',
      )),
    );
  }

  Future<void> _onAssignTicket(
    AssignTicketRequested event,
    Emitter<TicketState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await assignTicketUseCase(
      AssignTicketParams(ticketId: event.ticketId, technicianId: event.technicianId),
    );
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (ticket) => emit(state.copyWith(
        isLoading: false,
        selectedTicket: ticket,
        successMessage: 'Tiket berhasil didelegasikan',
      )),
    );
  }

  Future<void> _onFetchStats(
    FetchTicketStatsRequested event,
    Emitter<TicketState> emit,
  ) async {
    final result = await getTicketStatsUseCase(const NoParams());
    
    result.fold(
      (failure) => null,
      (stats) => emit(state.copyWith(stats: stats)),
    );
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<TicketState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    add(const FetchTicketsRequested(page: 0));
    add(const FetchAllTicketsRequested(page: 0));
  }

  Future<void> _onFilterStatusChanged(
    FilterStatusChanged event,
    Emitter<TicketState> emit,
  ) async {
    final filter = event.status == null ? TicketStatusFilter.all : TicketStatusFilter.values.byName(event.status!.name);
    emit(state.copyWith(statusFilter: filter));
    add(const FetchTicketsRequested(page: 0));
    add(const FetchAllTicketsRequested(page: 0));
  }

  Future<void> _onFilterCategoryChanged(
    FilterCategoryChanged event,
    Emitter<TicketState> emit,
  ) async {
    emit(state.copyWith(categoryFilter: event.category));
    add(const FetchTicketsRequested(page: 0));
    add(const FetchAllTicketsRequested(page: 0));
  }

  Future<void> _onFetchActivities(
    FetchTicketActivitiesRequested event,
    Emitter<TicketState> emit,
  ) async {
    emit(state.copyWith(activities: []));
    
    if (event.ticketId != null) {
      final result = await getTicketHistoryUseCase(event.ticketId!);
      result.fold(
        (failure) => emit(state.copyWith(errorMessage: failure.message)),
        (history) => emit(state.copyWith(activities: history)),
      );
    }
  }
}
