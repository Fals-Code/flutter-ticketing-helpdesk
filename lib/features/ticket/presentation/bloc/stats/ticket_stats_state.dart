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

  const TicketStatsState({
    this.stats = const TicketStats(),
    this.staffUsers = const [],
    this.history = const [],
    this.errorMessage,
    this.isLoading = false,
  });

  TicketStatsState copyWith({
    TicketStats? stats,
    List<AuthUser>? staffUsers,
    List<TicketHistoryEntity>? history,
    String? errorMessage,
    bool? isLoading,
  }) {
    return TicketStatsState(
      stats: stats ?? this.stats,
      staffUsers: staffUsers ?? this.staffUsers,
      history: history ?? this.history,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [stats, staffUsers, history, errorMessage, isLoading];
}
