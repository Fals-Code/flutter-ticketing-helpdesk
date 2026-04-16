import 'package:equatable/equatable.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';

class TicketDetailState extends Equatable {
  final bool isLoading;
  final TicketEntity? ticket;
  final List<CommentEntity> comments;
  final List<TicketHistoryEntity> history;
  final String? errorMessage;
  final String? successMessage;
  final bool isRatingSubmitting;

  const TicketDetailState({
    this.isLoading = false,
    this.ticket,
    this.comments = const [],
    this.history = const [],
    this.errorMessage,
    this.successMessage,
    this.isRatingSubmitting = false,
  });

  TicketDetailState copyWith({
    bool? isLoading,
    TicketEntity? ticket,
    List<CommentEntity>? comments,
    List<TicketHistoryEntity>? history,
    String? errorMessage,
    String? successMessage,
    bool? isRatingSubmitting,
  }) {
    return TicketDetailState(
      isLoading: isLoading ?? this.isLoading,
      ticket: ticket ?? this.ticket,
      comments: comments ?? this.comments,
      history: history ?? this.history,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isRatingSubmitting: isRatingSubmitting ?? this.isRatingSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        ticket,
        comments,
        history,
        errorMessage,
        successMessage,
        isRatingSubmitting,
      ];
}
