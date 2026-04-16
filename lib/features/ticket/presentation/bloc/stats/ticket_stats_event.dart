import 'package:equatable/equatable.dart';

abstract class TicketStatsEvent extends Equatable {
  const TicketStatsEvent();
  @override
  List<Object?> get props => [];
}

class FetchTicketStatsRequested extends TicketStatsEvent {
  final String? assignedToId;
  const FetchTicketStatsRequested({this.assignedToId});
  @override
  List<Object?> get props => [assignedToId];
}

class FetchStaffUsersRequested extends TicketStatsEvent {}

class FetchAllHistoryRequested extends TicketStatsEvent {
  final String? changedBy;
  const FetchAllHistoryRequested({this.changedBy});
  @override
  List<Object?> get props => [changedBy];
}

class ResetTicketStatsState extends TicketStatsEvent {}
