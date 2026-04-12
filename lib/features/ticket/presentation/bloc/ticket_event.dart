import 'package:equatable/equatable.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import '../../../../core/constants/enums.dart';

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
  final String userId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final List<String> imagePaths;

  const CreateTicketRequested({
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [userId, title, description, category, priority, imagePaths];
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
  final String? assignedToId;
  const FetchAllTicketsRequested({
    required this.page, 
    this.limit = 10, 
    this.status,
    this.assignedToId,
  });
  @override
  List<Object?> get props => [page, limit, status, assignedToId];
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
  final String? assignedToId;
  const FetchTicketStatsRequested({this.assignedToId});
  @override
  List<Object?> get props => [assignedToId];
}

class FetchTicketActivitiesRequested extends TicketEvent {
  final String? ticketId; // null means all activities for staff
  final String? changedBy; // filter by technician who changed it

  const FetchTicketActivitiesRequested({this.ticketId, this.changedBy});

  @override
  List<Object?> get props => [ticketId, changedBy];
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

class StartTicketSubscription extends TicketEvent {
  final String? userId;
  final bool isStaff;
  final bool isTechnician;

  const StartTicketSubscription({
    this.userId, 
    this.isStaff = false,
    this.isTechnician = false,
  });

  @override
  List<Object?> get props => [userId, isStaff, isTechnician];
}

class TicketStreamUpdated extends TicketEvent {
  final List<TicketEntity> tickets;
  const TicketStreamUpdated(this.tickets);
  @override
  List<Object?> get props => [tickets];
}

class StartTicketCommentsSubscription extends TicketEvent {
  final String ticketId;
  const StartTicketCommentsSubscription(this.ticketId);
  @override
  List<Object?> get props => [ticketId];
}

class CommentStreamUpdated extends TicketEvent {
  final List<CommentEntity> comments;
  const CommentStreamUpdated(this.comments);
  @override
  List<Object?> get props => [comments];
}

class ResetTicketState extends TicketEvent {}
