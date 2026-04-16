import 'package:equatable/equatable.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';

class TicketStatsState extends Equatable {
  final TicketStats stats;
  final List<AuthUser> staffUsers;
  final List<TicketHistoryEntity> history;
  final String? errorMessage;
  final bool isLoading;
  final DateTime? startDate;
  final DateTime? endDate;

  const TicketStatsState({
    this.stats = const TicketStats(),
    this.staffUsers = const [],
    this.history = const [],
    this.errorMessage,
    this.isLoading = false,
    this.startDate,
    this.endDate,
  });

  TicketStatsState copyWith({
    TicketStats? stats,
    List<AuthUser>? staffUsers,
    List<TicketHistoryEntity>? history,
    String? errorMessage,
    bool? isLoading,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TicketStatsState(
      stats: stats ?? this.stats,
      staffUsers: staffUsers ?? this.staffUsers,
      history: history ?? this.history,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [stats, staffUsers, history, errorMessage, isLoading, startDate, endDate];
}
