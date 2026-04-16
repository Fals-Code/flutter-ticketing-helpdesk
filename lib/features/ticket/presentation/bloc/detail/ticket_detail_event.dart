import 'package:equatable/equatable.dart';
import 'package:uts/core/constants/enums.dart';

abstract class TicketDetailEvent extends Equatable {
  const TicketDetailEvent();
  @override
  List<Object?> get props => [];
}

class FetchTicketDetailRequested extends TicketDetailEvent {
  final String ticketId;
  const FetchTicketDetailRequested(this.ticketId);
  @override
  List<Object?> get props => [ticketId];
}

class UpdateTicketStatusRequested extends TicketDetailEvent {
  final String ticketId;
  final TicketStatus status;
  const UpdateTicketStatusRequested({required this.ticketId, required this.status});
  @override
  List<Object?> get props => [ticketId, status];
}

class AssignTicketRequested extends TicketDetailEvent {
  final String ticketId;
  final String technicianId;
  const AssignTicketRequested({required this.ticketId, required this.technicianId});
  @override
  List<Object?> get props => [ticketId, technicianId];
}

class AddCommentRequested extends TicketDetailEvent {
  final String ticketId;
  final String message;
  const AddCommentRequested({required this.ticketId, required this.message});
  @override
  List<Object?> get props => [ticketId, message];
}

class FetchTicketActivitiesRequested extends TicketDetailEvent {
  final String ticketId;
  const FetchTicketActivitiesRequested(this.ticketId);
  @override
  List<Object?> get props => [ticketId];
}

class StartTicketCommentsSubscription extends TicketDetailEvent {
  final String ticketId;
  const StartTicketCommentsSubscription(this.ticketId);
  @override
  List<Object?> get props => [ticketId];
}

class CommentStreamUpdated extends TicketDetailEvent {
  final List<dynamic> comments; // CommentEntity
  const CommentStreamUpdated(this.comments);
  @override
  List<Object?> get props => [comments];
}

class SubmitRatingRequested extends TicketDetailEvent {
  final String ticketId;
  final int rating;
  final String feedback;

  const SubmitRatingRequested({
    required this.ticketId,
    required this.rating,
    required this.feedback,
  });

  @override
  List<Object?> get props => [ticketId, rating, feedback];
}

class ResetTicketDetailState extends TicketDetailEvent {}
