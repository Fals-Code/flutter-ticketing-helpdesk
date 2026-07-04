import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/services/realtime_session_service.dart';
import 'package:uts/core/services/connectivity_service.dart';
import 'package:uts/features/ticket/data/datasources/ticket_local_data_source.dart';
import 'package:uts/features/ticket/data/models/ticket_model.dart';
import 'package:uts/features/ticket/domain/entities/create_ticket_params.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/services/ticket_collection_utils.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/value_objects/ticket_query.dart';

import 'ticket_list_event.dart';
import 'ticket_list_state.dart';

enum _TicketListMode {
  user,
  staff,
}

class TicketListBloc extends Bloc<TicketListEvent, TicketListState> {
  final GetTicketsUseCase getTicketsUseCase;
  final GetAllTicketsUseCase getAllTicketsUseCase;
  final WatchTicketsUseCase watchTicketsUseCase;
  final CreateTicketUseCase createTicketUseCase;
  final TicketLocalDataSource localDataSource;
  final ConnectivityService? connectivityService;
  final Stream<ConnectionStatus>? connectivityOverride;

  StreamSubscription<List<TicketEntity>>? _ticketSubscription;
  StreamSubscription<ConnectionStatus>? _connectivitySubscription;
  Timer? _realtimeRetryTimer;

  _TicketListMode? _activeMode;
  int _userGeneration = 0;
  int _staffGeneration = 0;
  int _subscriptionGeneration = 0;
  List<TicketEntity> _latestRealtimeSnapshot = const [];
  String? _subscriptionAssignedToId;
  bool _subscriptionIsStaff = false;
  int _realtimeRetryCount = 0;

  static const int _maxRealtimeRetryCount = 3;
  static const Duration _baseRealtimeRetryDelay = Duration(milliseconds: 300);

  TicketListBloc({
    required this.getTicketsUseCase,
    required this.getAllTicketsUseCase,
    required this.watchTicketsUseCase,
    required this.createTicketUseCase,
    required this.localDataSource,
    this.connectivityService,
    this.connectivityOverride,
  }) : super(TicketListState.initial()) {
    on<FetchTicketsRequested>(_onFetchTickets);
    on<FetchAllTicketsRequested>(_onFetchAllTickets);
    on<SearchTicketsRequested>(_onSearchQueryChanged);
    on<FilterStatusChanged>(_onFilterStatusChanged);
    on<FilterCategoryChanged>(_onFilterCategoryChanged);
    on<FilterDateRangeChanged>(_onFilterDateRangeChanged);
    on<StartTicketListSubscription>(_onStartSubscription);
    on<CreateTicketRequested>(_onCreateTicket);
    on<TicketCreatedLocally>(_onTicketCreatedLocally);
    on<TicketDeletedLocally>(_onTicketDeletedLocally);
    on<ResetTicketListState>(_onResetState);
    on<_RealtimeTicketsUpdated>(_onRealtimeTicketsUpdated);
    on<_RealtimeTicketsFailed>(_onRealtimeTicketsFailed);

    _connectivitySubscription = (connectivityOverride ??
            connectivityService?.connectionStream ??
            const Stream<ConnectionStatus>.empty())
        .listen((status) {
      if (status == ConnectionStatus.online && !isClosed) {
        _refreshActiveList();
      }
    });
  }

  Future<void> _onFetchTickets(
    FetchTicketsRequested event,
    Emitter<TicketListState> emit,
  ) async {
    _activeMode = _TicketListMode.user;
    final isInitial = event.page == 0;
    final isLoadMore = !isInitial;

    if (isLoadMore && (state.isLoadingMore || !state.hasMore)) {
      return;
    }

    if (isInitial) {
      _userGeneration++;
    } else if (_userGeneration == 0) {
      _userGeneration = 1;
    }
    final requestGeneration = _userGeneration;

    final query = state.query.copyWith(
      page: event.page,
      limit: event.limit,
      offset: event.page * event.limit,
    );

    emit(
      state.copyWith(
        query: isInitial ? query : state.query,
        isInitialLoading: isInitial && state.tickets.isEmpty,
        isRefreshing: isInitial && state.tickets.isNotEmpty,
        isLoadingMore: isLoadMore,
        clearErrorMessage: true,
        clearLoadMoreErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await getTicketsUseCase(GetTicketsParams(query: query));
    if (requestGeneration != _userGeneration || isClosed) {
      return;
    }

    await result.fold<Future<void>>(
      (failure) async {
        if (!isLoadMore) {
          try {
            final cachedTickets = await localDataSource.getCachedTickets();
            if (!isClosed && requestGeneration == _userGeneration) {
              emit(
                state.copyWith(
                  query: query,
                  tickets: cachedTickets
                      .map((ticket) => ticket.toEntity())
                      .toList(growable: false),
                  isInitialLoading: false,
                  isRefreshing: false,
                  isLoadingMore: false,
                  hasMore: false,
                  isOffline: true,
                  successMessage: 'Menampilkan data tiket dari cache.',
                  clearErrorMessage: true,
                  clearLoadMoreErrorMessage: true,
                ),
              );
              return;
            }
          } catch (_) {
            // Fallback to server failure state when user-scoped cache is unavailable.
          }
        }

        emit(
          state.copyWith(
            isInitialLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            errorMessage: isLoadMore ? state.errorMessage : failure.message,
            loadMoreErrorMessage: isLoadMore ? failure.message : null,
          ),
        );
      },
      (pageResult) async {
        final merged = isInitial
            ? sortTicketsDeterministically(pageResult.items)
            : mergeTicketPage(
                existing: state.tickets,
                incoming: pageResult.items,
              );

        final items = _applyRealtimeWindow(
          currentItems: merged,
          query: query,
          hasMore: pageResult.hasMore,
          assignedToId: null,
        );

        await localDataSource.cacheTickets(
          items.map(TicketModel.fromEntity).toList(growable: false),
        );

        emit(
          state.copyWith(
            query: query,
            tickets: items,
            isInitialLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            hasMore: pageResult.hasMore,
            currentPage: query.page,
            isOffline: false,
            clearErrorMessage: true,
            clearLoadMoreErrorMessage: true,
          ),
        );
      },
    );
  }

  Future<void> _onFetchAllTickets(
    FetchAllTicketsRequested event,
    Emitter<TicketListState> emit,
  ) async {
    _activeMode = _TicketListMode.staff;
    final isInitial = event.page == 0;
    final isLoadMore = !isInitial;
    final assignedToId = event.assignedToId ?? state.assignedToId;

    if (isLoadMore && (state.isLoadingMore || !state.hasMoreAll)) {
      return;
    }

    if (isInitial) {
      _staffGeneration++;
    } else if (_staffGeneration == 0) {
      _staffGeneration = 1;
    }
    final requestGeneration = _staffGeneration;

    final query = state.query.copyWith(
      page: event.page,
      limit: event.limit,
      offset: event.page * event.limit,
    );

    if (isInitial &&
        _subscriptionIsStaff &&
        (_subscriptionAssignedToId != assignedToId)) {
      add(StartTicketListSubscription(
        assignedToId: assignedToId,
        isStaff: true,
      ));
    }

    emit(
      state.copyWith(
        query: isInitial ? query : state.query,
        assignedToId: assignedToId,
        isInitialLoading: isInitial && state.allTickets.isEmpty,
        isRefreshing: isInitial && state.allTickets.isNotEmpty,
        isLoadingMore: isLoadMore,
        clearErrorMessage: true,
        clearLoadMoreErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await getAllTicketsUseCase(
      GetTicketsParams(
        query: query,
        assignedToId: assignedToId,
      ),
    );
    if (requestGeneration != _staffGeneration || isClosed) {
      return;
    }

    await result.fold<Future<void>>(
      (failure) async {
        if (!isLoadMore) {
          try {
            final cachedTickets = await localDataSource.getCachedTickets();
            if (!isClosed && requestGeneration == _staffGeneration) {
              emit(
                state.copyWith(
                  query: query,
                  assignedToId: assignedToId,
                  allTickets: cachedTickets
                      .map((ticket) => ticket.toEntity())
                      .toList(growable: false),
                  isInitialLoading: false,
                  isRefreshing: false,
                  isLoadingMore: false,
                  hasMoreAll: false,
                  isOffline: true,
                  successMessage: 'Menampilkan data tiket dari cache.',
                  clearErrorMessage: true,
                  clearLoadMoreErrorMessage: true,
                ),
              );
              return;
            }
          } catch (_) {
            // Fallback to server failure state when user-scoped cache is unavailable.
          }
        }

        emit(
          state.copyWith(
            isInitialLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            errorMessage: isLoadMore ? state.errorMessage : failure.message,
            loadMoreErrorMessage: isLoadMore ? failure.message : null,
          ),
        );
      },
      (pageResult) async {
        final merged = isInitial
            ? sortTicketsDeterministically(pageResult.items)
            : mergeTicketPage(
                existing: state.allTickets,
                incoming: pageResult.items,
              );

        final items = _applyRealtimeWindow(
          currentItems: merged,
          query: query,
          hasMore: pageResult.hasMore,
          assignedToId: assignedToId,
        );

        await localDataSource.cacheTickets(
          items.map(TicketModel.fromEntity).toList(growable: false),
        );

        emit(
          state.copyWith(
            query: query,
            assignedToId: assignedToId,
            allTickets: items,
            isInitialLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            hasMoreAll: pageResult.hasMore,
            allTicketsPage: query.page,
            isOffline: false,
            clearErrorMessage: true,
            clearLoadMoreErrorMessage: true,
          ),
        );
      },
    );
  }

  Future<void> _onSearchQueryChanged(
    SearchTicketsRequested event,
    Emitter<TicketListState> emit,
  ) async {
    final updatedQuery = state.query.copyWith(
      search: event.query,
      page: 0,
      offset: 0,
      clearSearch: event.query.trim().isEmpty,
    );

    emit(
      state.copyWith(
        query: updatedQuery,
        clearErrorMessage: true,
        clearLoadMoreErrorMessage: true,
      ),
    );
    _refreshActiveList();
  }

  Future<void> _onFilterStatusChanged(
    FilterStatusChanged event,
    Emitter<TicketListState> emit,
  ) async {
    final updatedQuery = applyStatusFilterToQuery(state.query, event.filter);
    emit(
      state.copyWith(
        query: updatedQuery,
        clearErrorMessage: true,
        clearLoadMoreErrorMessage: true,
      ),
    );
    _refreshActiveList();
  }

  Future<void> _onFilterCategoryChanged(
    FilterCategoryChanged event,
    Emitter<TicketListState> emit,
  ) async {
    final updatedQuery = state.query.copyWith(
      category: event.category,
      clearCategory: event.category == null || event.category!.trim().isEmpty,
      page: 0,
      offset: 0,
    );

    emit(
      state.copyWith(
        query: updatedQuery,
        clearErrorMessage: true,
        clearLoadMoreErrorMessage: true,
      ),
    );
    _refreshActiveList();
  }

  Future<void> _onFilterDateRangeChanged(
    FilterDateRangeChanged event,
    Emitter<TicketListState> emit,
  ) async {
    final updatedQuery = state.query.copyWith(
      startDate: event.startDate,
      endDate: event.endDate,
      clearStartDate: event.startDate == null,
      clearEndDate: event.endDate == null,
      page: 0,
      offset: 0,
    );

    emit(
      state.copyWith(
        query: updatedQuery,
        clearErrorMessage: true,
        clearLoadMoreErrorMessage: true,
      ),
    );
    _refreshActiveList();
  }

  Future<void> _onStartSubscription(
    StartTicketListSubscription event,
    Emitter<TicketListState> emit,
  ) async {
    _subscriptionGeneration++;
    final generation = _subscriptionGeneration;
    _subscriptionAssignedToId = event.assignedToId;
    _subscriptionIsStaff = event.isStaff;

    final previous = _ticketSubscription;
    _ticketSubscription = null;
    await previous?.cancel();

    if (isClosed || generation != _subscriptionGeneration) {
      return;
    }

    _ticketSubscription = watchTicketsUseCase(
      userId: event.userId,
      assignedToId: event.assignedToId,
    ).listen(
      (tickets) {
        if (!isClosed && generation == _subscriptionGeneration) {
          _realtimeRetryCount = 0;
          _realtimeRetryTimer?.cancel();
          _realtimeRetryTimer = null;
          add(_RealtimeTicketsUpdated(
            tickets: tickets,
            isStaff: event.isStaff,
            assignedToId: event.assignedToId,
          ));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed && generation == _subscriptionGeneration) {
          add(_RealtimeTicketsFailed(
            error: error,
            isStaff: event.isStaff,
            userId: event.userId,
            assignedToId: event.assignedToId,
          ));
        }
      },
    );
  }

  void _onRealtimeTicketsUpdated(
    _RealtimeTicketsUpdated event,
    Emitter<TicketListState> emit,
  ) {
    _latestRealtimeSnapshot = event.tickets;
    final query = state.query;

    if (event.isStaff) {
      emit(
        state.copyWith(
          allTickets: applyRealtimeSnapshot(
            currentItems: state.allTickets,
            snapshotItems: event.tickets,
            query: query,
            hasMore: state.hasMoreAll,
            assignedToId: event.assignedToId,
          ),
          clearRealtimeWarningMessage: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        tickets: applyRealtimeSnapshot(
          currentItems: state.tickets,
          snapshotItems: event.tickets,
          query: query,
          hasMore: state.hasMore,
        ),
        clearRealtimeWarningMessage: true,
      ),
    );
  }

  void _onRealtimeTicketsFailed(
    _RealtimeTicketsFailed event,
    Emitter<TicketListState> emit,
  ) {
    _scheduleRealtimeRetry(event);
    emit(
      state.copyWith(
        realtimeWarningMessage: _safeRealtimeMessage(event.error),
      ),
    );
  }

  Future<void> _onCreateTicket(
    CreateTicketRequested event,
    Emitter<TicketListState> emit,
  ) async {
    emit(
      state.copyWith(
        isInitialLoading: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await createTicketUseCase(
      CreateTicketParams(
        title: event.title,
        description: event.description,
        category: event.category,
        attachments: event.attachments,
      ),
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isInitialLoading: false,
            errorMessage: failure.message,
          ),
        );
      },
      (_) {
        emit(
          state.copyWith(
            isInitialLoading: false,
            successMessage: 'Laporan berhasil dibuat',
            clearErrorMessage: true,
          ),
        );
        _refreshActiveList();
      },
    );
  }

  Future<void> _onResetState(
    ResetTicketListState event,
    Emitter<TicketListState> emit,
  ) async {
    _userGeneration++;
    _staffGeneration++;
    _subscriptionGeneration++;
    _latestRealtimeSnapshot = const [];
    _subscriptionAssignedToId = null;
    _subscriptionIsStaff = false;
    _activeMode = null;
    _realtimeRetryCount = 0;
    _realtimeRetryTimer?.cancel();
    _realtimeRetryTimer = null;

    final previous = _ticketSubscription;
    _ticketSubscription = null;
    await previous?.cancel();
    emit(TicketListState.initial());
  }

  void _onTicketDeletedLocally(
    TicketDeletedLocally event,
    Emitter<TicketListState> emit,
  ) {
    emit(
      state.copyWith(
        tickets: state.tickets
            .where((ticket) => ticket.id != event.ticketId)
            .toList(growable: false),
        allTickets: state.allTickets
            .where((ticket) => ticket.id != event.ticketId)
            .toList(growable: false),
        clearErrorMessage: true,
        clearLoadMoreErrorMessage: true,
      ),
    );
  }

  void _onTicketCreatedLocally(
    TicketCreatedLocally event,
    Emitter<TicketListState> emit,
  ) {
    final query = state.query;
    final shouldShowInUserList = matchesTicketQuery(event.ticket, query);
    final shouldShowInStaffList = matchesTicketQuery(
      event.ticket,
      query,
      assignedToId: state.assignedToId,
    );

    emit(
      state.copyWith(
        tickets: shouldShowInUserList
            ? upsertRealtimeTicket(
                existing: state.tickets,
                incoming: event.ticket,
              )
            : state.tickets,
        allTickets: shouldShowInStaffList
            ? upsertRealtimeTicket(
                existing: state.allTickets,
                incoming: event.ticket,
              )
            : state.allTickets,
        clearErrorMessage: true,
        clearLoadMoreErrorMessage: true,
      ),
    );
  }

  List<TicketEntity> _applyRealtimeWindow({
    required List<TicketEntity> currentItems,
    required TicketQuery query,
    required bool hasMore,
    String? assignedToId,
  }) {
    if (_latestRealtimeSnapshot.isEmpty) {
      return currentItems;
    }

    return applyRealtimeSnapshot(
      currentItems: currentItems,
      snapshotItems: _latestRealtimeSnapshot,
      query: query,
      hasMore: hasMore,
      assignedToId: assignedToId,
    );
  }

  void _refreshActiveList() {
    if (isClosed) {
      return;
    }

    final limit = state.query.limit;
    switch (_activeMode) {
      case _TicketListMode.staff:
        add(FetchAllTicketsRequested(
          page: 0,
          limit: limit,
          assignedToId: state.assignedToId,
        ));
        break;
      case _TicketListMode.user:
        add(FetchTicketsRequested(page: 0, limit: limit));
        break;
      case null:
        break;
    }
  }

  void _scheduleRealtimeRetry(_RealtimeTicketsFailed event) {
    if (_isAuthenticationFailure(event.error)) {
      return;
    }
    if (_realtimeRetryCount >= _maxRealtimeRetryCount) {
      return;
    }
    _realtimeRetryTimer?.cancel();
    _realtimeRetryCount++;
    final delay = _baseRealtimeRetryDelay * _realtimeRetryCount;
    _realtimeRetryTimer = Timer(delay, () {
      if (isClosed) return;
      add(StartTicketListSubscription(
        userId: event.userId,
        assignedToId: event.assignedToId,
        isStaff: event.isStaff,
      ));
    });
  }

  bool _isAuthenticationFailure(Object error) {
    return error is RealtimeSessionException && error.isAuthenticationFailure;
  }

  String _safeRealtimeMessage(Object error) {
    if (_isAuthenticationFailure(error)) {
      return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
    }
    return 'Pembaruan langsung sedang terputus. Data tetap dapat dilihat dan akan disinkronkan kembali.';
  }

  @override
  Future<void> close() async {
    _subscriptionGeneration++;
    _realtimeRetryTimer?.cancel();
    final ticketSubscription = _ticketSubscription;
    final connectivitySubscription = _connectivitySubscription;
    _realtimeRetryTimer = null;
    _ticketSubscription = null;
    _connectivitySubscription = null;

    await ticketSubscription?.cancel();
    await connectivitySubscription?.cancel();
    await super.close();
  }
}

class _RealtimeTicketsUpdated extends TicketListEvent {
  final List<TicketEntity> tickets;
  final bool isStaff;
  final String? assignedToId;

  const _RealtimeTicketsUpdated({
    required this.tickets,
    required this.isStaff,
    this.assignedToId,
  });

  @override
  List<Object?> get props => [tickets, isStaff, assignedToId];
}

class _RealtimeTicketsFailed extends TicketListEvent {
  final Object error;
  final bool isStaff;
  final String? userId;
  final String? assignedToId;

  const _RealtimeTicketsFailed({
    required this.error,
    required this.isStaff,
    this.userId,
    this.assignedToId,
  });

  @override
  List<Object?> get props => [error, isStaff, userId, assignedToId];
}
