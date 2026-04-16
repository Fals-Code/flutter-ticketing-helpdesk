import 'package:equatable/equatable.dart';

abstract class TicketStatsEvent extends Equatable {
  const TicketStatsEvent();
  @override
  List<Object?> get props => [];
}

class FetchTicketStatsRequested extends TicketStatsEvent {
  final String? assignedToId;
  final DateTime? startDate;
  final DateTime? endDate;

  const FetchTicketStatsRequested({
    this.assignedToId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [assignedToId, startDate, endDate];
}

class FetchStaffUsersRequested extends TicketStatsEvent {}

class FetchAllHistoryRequested extends TicketStatsEvent {
  final String? changedBy;
  final DateTime? startDate;
  final DateTime? endDate;
  const FetchAllHistoryRequested({this.changedBy, this.startDate, this.endDate});
  @override
  List<Object?> get props => [changedBy, startDate, endDate];
}

class ResetTicketStatsState extends TicketStatsEvent {}
