import 'package:equatable/equatable.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';

enum TicketStatusFilter { all, open, inProgress, resolved, closed }

class TicketListState extends Equatable {
  final bool isLoading;
  final List<TicketEntity> tickets;
  final List<TicketEntity> allTickets;
  final String? errorMessage;
  final String? successMessage;
  final bool isLastPage;
  final bool isLastPageAll;
  final String searchQuery;
  final TicketStatusFilter statusFilter;
  final String? categoryFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isOffline;

  const TicketListState({
    this.isLoading = false,
    this.tickets = const [],
    this.allTickets = const [],
    this.errorMessage,
    this.successMessage,
    this.isLastPage = false,
    this.isLastPageAll = false,
    this.searchQuery = '',
    this.statusFilter = TicketStatusFilter.all,
    this.categoryFilter,
    this.startDate,
    this.endDate,
    this.isOffline = false,
  });

  TicketListState copyWith({
    bool? isLoading,
    List<TicketEntity>? tickets,
    List<TicketEntity>? allTickets,
    String? errorMessage,
    String? successMessage,
    bool? isLastPage,
    bool? isLastPageAll,
    String? searchQuery,
    TicketStatusFilter? statusFilter,
    String? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool? isOffline,
  }) {
    return TicketListState(
      isLoading: isLoading ?? this.isLoading,
      tickets: tickets ?? this.tickets,
      allTickets: allTickets ?? this.allTickets,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isLastPage: isLastPage ?? this.isLastPage,
      isLastPageAll: isLastPageAll ?? this.isLastPageAll,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        tickets,
        allTickets,
        errorMessage,
        successMessage,
        isLastPage,
        isLastPageAll,
        searchQuery,
        statusFilter,
        categoryFilter,
        startDate,
        endDate,
        isOffline,
      ];
}
