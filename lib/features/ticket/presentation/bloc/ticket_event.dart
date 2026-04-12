import 'package:equatable/equatable.dart';

import 'package:uts/core/constants/enums.dart';

abstract class TicketEvent extends Equatable {
  const TicketEvent();
  @override
  List<Object?> get props => [];
}

class FetchTicketsRequested extends TicketEvent {
  final int page;
  final int limit;
  const FetchTicketsRequested({required this.page, this.limit = 10});
  @override
  List<Object?> get props => [page, limit];
}

class CreateTicketRequested extends TicketEvent {
  final String title;
  final String description;
  final String category;
  final String priority;
  final List<String> imagePaths;

  const CreateTicketRequested({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [title, description, category, priority, imagePaths];
}

class FetchTicketDetailRequested extends TicketEvent {
  final String ticketId;
  const FetchTicketDetailRequested(this.ticketId);
  @override
  List<Object?> get props => [ticketId];
}

class FetchAllTicketsRequested extends TicketEvent {
  final int page;
  final int limit;
  final String? status;
  const FetchAllTicketsRequested({required this.page, this.limit = 10, this.status});
  @override
  List<Object?> get props => [page, limit, status];
}

class FetchStaffUsersRequested extends TicketEvent {
  const FetchStaffUsersRequested();
}

class UpdateTicketStatusRequested extends TicketEvent {
  final String ticketId;
  final TicketStatus status;
  const UpdateTicketStatusRequested({required this.ticketId, required this.status});
  @override
  List<Object> get props => [ticketId, status];
}

class AssignTicketRequested extends TicketEvent {
  final String ticketId;
  final String technicianId;
  const AssignTicketRequested({required this.ticketId, required this.technicianId});
  @override
  List<Object> get props => [ticketId, technicianId];
}

class AddCommentRequested extends TicketEvent {
  final String ticketId;
  final String message;
  const AddCommentRequested({required this.ticketId, required this.message});
  @override
  List<Object?> get props => [ticketId, message];
}

class FetchTicketStatsRequested extends TicketEvent {
  const FetchTicketStatsRequested();
}

class FetchTicketActivitiesRequested extends TicketEvent {
  final String? ticketId; // null means all activities for staff

  const FetchTicketActivitiesRequested({this.ticketId});

  @override
  List<Object?> get props => [ticketId];
}

class SearchQueryChanged extends TicketEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class FilterStatusChanged extends TicketEvent {
  final TicketStatus? status;
  const FilterStatusChanged(this.status);
  @override
  List<Object?> get props => [status];
}

class FilterCategoryChanged extends TicketEvent {
  final String? category;
  const FilterCategoryChanged(this.category);
  @override
  List<Object?> get props => [category];
}

class StartTicketSubscription extends TicketEvent {}

class TicketStreamUpdated extends TicketEvent {
  final List<TicketEntity> tickets;
  const TicketStreamUpdated(this.tickets);
  @override
  List<Object?> get props => [tickets];
}
