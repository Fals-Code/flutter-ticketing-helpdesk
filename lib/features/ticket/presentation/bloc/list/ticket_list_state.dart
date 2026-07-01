import 'package:equatable/equatable.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/services/ticket_collection_utils.dart';
import 'package:uts/features/ticket/domain/value_objects/ticket_query.dart';

class TicketListState extends Equatable {
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final List<TicketEntity> tickets;
  final List<TicketEntity> allTickets;
  final String? errorMessage;
  final String? loadMoreErrorMessage;
  final String? realtimeWarningMessage;
  final String? successMessage;
  final bool hasMore;
  final bool hasMoreAll;
  final TicketQuery query;
  final bool isOffline;
  final int currentPage;
  final int allTicketsPage;
  final String? assignedToId;

  const TicketListState({
    required this.isInitialLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.tickets,
    required this.allTickets,
    required this.errorMessage,
    required this.loadMoreErrorMessage,
    required this.realtimeWarningMessage,
    required this.successMessage,
    required this.hasMore,
    required this.hasMoreAll,
    required this.query,
    required this.isOffline,
    required this.currentPage,
    required this.allTicketsPage,
    required this.assignedToId,
  });

  factory TicketListState.initial() {
    return TicketListState(
      isInitialLoading: false,
      isRefreshing: false,
      isLoadingMore: false,
      tickets: const [],
      allTickets: const [],
      errorMessage: null,
      loadMoreErrorMessage: null,
      realtimeWarningMessage: null,
      successMessage: null,
      hasMore: true,
      hasMoreAll: true,
      query: TicketQuery(),
      isOffline: false,
      currentPage: 0,
      allTicketsPage: 0,
      assignedToId: null,
    );
  }

  bool get isLoading => isInitialLoading || isRefreshing || isLoadingMore;
  bool get isLastPage => !hasMore;
  bool get isLastPageAll => !hasMoreAll;
  String get searchQuery => query.search ?? '';
  TicketStatusFilter get statusFilter => ticketStatusFilterFromQuery(query);
  String? get categoryFilter => query.category;
  DateTime? get startDate => query.startDate;
  DateTime? get endDate => query.endDate;

  TicketListState copyWith({
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    List<TicketEntity>? tickets,
    List<TicketEntity>? allTickets,
    String? errorMessage,
    String? loadMoreErrorMessage,
    String? realtimeWarningMessage,
    String? successMessage,
    bool clearErrorMessage = false,
    bool clearLoadMoreErrorMessage = false,
    bool clearRealtimeWarningMessage = false,
    bool clearSuccessMessage = false,
    bool? hasMore,
    bool? hasMoreAll,
    TicketQuery? query,
    bool? isOffline,
    int? currentPage,
    int? allTicketsPage,
    String? assignedToId,
  }) {
    return TicketListState(
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      tickets: tickets ?? this.tickets,
      allTickets: allTickets ?? this.allTickets,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      loadMoreErrorMessage: clearLoadMoreErrorMessage
          ? null
          : (loadMoreErrorMessage ?? this.loadMoreErrorMessage),
      realtimeWarningMessage: clearRealtimeWarningMessage
          ? null
          : (realtimeWarningMessage ?? this.realtimeWarningMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      hasMore: hasMore ?? this.hasMore,
      hasMoreAll: hasMoreAll ?? this.hasMoreAll,
      query: query ?? this.query,
      isOffline: isOffline ?? this.isOffline,
      currentPage: currentPage ?? this.currentPage,
      allTicketsPage: allTicketsPage ?? this.allTicketsPage,
      assignedToId: assignedToId ?? this.assignedToId,
    );
  }

  @override
  List<Object?> get props => [
        isInitialLoading,
        isRefreshing,
        isLoadingMore,
        tickets,
        allTickets,
        errorMessage,
        loadMoreErrorMessage,
        realtimeWarningMessage,
        successMessage,
        hasMore,
        hasMoreAll,
        query,
        isOffline,
        currentPage,
        allTicketsPage,
        assignedToId,
      ];
}
