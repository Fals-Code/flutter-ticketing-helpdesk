import 'package:equatable/equatable.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';

enum TicketStatusFilter { all, open, inProgress, resolved, closed }

class TicketState extends Equatable {
  final bool isLoading;
  final List<TicketEntity> tickets;
  final List<TicketEntity> allTickets;
  final TicketEntity? selectedTicket;
  final List<CommentEntity> comments;
  final List<TicketHistoryEntity> history;
  final List<AuthUser> staffUsers;
  final TicketStats stats;
  final String? errorMessage;
  final String? successMessage;
  final bool isLastPage;
  final bool isLastPageAll;
  final String searchQuery;
  final TicketStatusFilter statusFilter;
  final String? categoryFilter;

  const TicketState({
    this.isLoading = false,
    this.tickets = const [],
    this.allTickets = const [],
    this.selectedTicket,
    this.comments = const [],
    this.history = const [],
    this.staffUsers = const [],
    this.stats = const TicketStats(),
    this.errorMessage,
    this.successMessage,
    this.isLastPage = false,
    this.isLastPageAll = false,
    this.searchQuery = '',
    this.statusFilter = TicketStatusFilter.all,
    this.categoryFilter,
  });

  TicketState copyWith({
    bool? isLoading,
    List<TicketEntity>? tickets,
    List<TicketEntity>? allTickets,
    TicketEntity? selectedTicket,
    List<CommentEntity>? comments,
    List<TicketHistoryEntity>? history,
    List<AuthUser>? staffUsers,
    TicketStats? stats,
    String? errorMessage,
    String? successMessage,
    bool? isLastPage,
    bool? isLastPageAll,
    String? searchQuery,
    TicketStatusFilter? statusFilter,
    String? categoryFilter,
  }) {
    return TicketState(
      isLoading: isLoading ?? this.isLoading,
      tickets: tickets ?? this.tickets,
      allTickets: allTickets ?? this.allTickets,
      selectedTicket: selectedTicket ?? this.selectedTicket,
      comments: comments ?? this.comments,
      history: history ?? this.history,
      staffUsers: staffUsers ?? this.staffUsers,
      stats: stats ?? this.stats,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isLastPage: isLastPage ?? this.isLastPage,
      isLastPageAll: isLastPageAll ?? this.isLastPageAll,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        tickets,
        allTickets,
        selectedTicket,
        comments,
        history,
        staffUsers,
        stats,
        errorMessage,
        successMessage,
        isLastPage,
        isLastPageAll,
        searchQuery,
        statusFilter,
        categoryFilter,
      ];
}
