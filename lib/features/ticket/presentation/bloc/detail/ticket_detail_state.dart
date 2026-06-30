import 'package:equatable/equatable.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';

enum TicketDetailStatus {
  initial,
  loading,
  loaded,
  refreshing,
  notFound,
  unauthorized,
  failure,
}

class TicketDetailState extends Equatable {
  final TicketDetailStatus status;
  final TicketEntity? ticket;
  final List<CommentEntity> comments;
  final List<TicketHistoryEntity> history;
  final String? errorMessage;
  final String? successMessage;
  final bool isRatingSubmitting;
  final bool isCommentSubmitting;
  final bool isDeleting;
  final String? deletedTicketId;
  final bool isOffline;

  const TicketDetailState({
    this.status = TicketDetailStatus.initial,
    this.ticket,
    this.comments = const [],
    this.history = const [],
    this.errorMessage,
    this.successMessage,
    this.isRatingSubmitting = false,
    this.isCommentSubmitting = false,
    this.isDeleting = false,
    this.deletedTicketId,
    this.isOffline = false,
  });

  bool get isLoading =>
      status == TicketDetailStatus.loading ||
      status == TicketDetailStatus.refreshing;

  bool get isNotFound => status == TicketDetailStatus.notFound;
  bool get isUnauthorized => status == TicketDetailStatus.unauthorized;

  TicketDetailState copyWith({
    TicketDetailStatus? status,
    TicketEntity? ticket,
    List<CommentEntity>? comments,
    List<TicketHistoryEntity>? history,
    String? errorMessage,
    String? successMessage,
    bool clearErrorMessage = false,
    bool clearSuccessMessage = false,
    bool? isRatingSubmitting,
    bool? isCommentSubmitting,
    bool? isDeleting,
    String? deletedTicketId,
    bool clearDeletedTicketId = false,
    bool? isOffline,
    bool clearTicket = false,
  }) {
    return TicketDetailState(
      status: status ?? this.status,
      ticket: clearTicket ? null : (ticket ?? this.ticket),
      comments: comments ?? this.comments,
      history: history ?? this.history,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      isRatingSubmitting: isRatingSubmitting ?? this.isRatingSubmitting,
      isCommentSubmitting: isCommentSubmitting ?? this.isCommentSubmitting,
      isDeleting: isDeleting ?? this.isDeleting,
      deletedTicketId: clearDeletedTicketId
          ? null
          : (deletedTicketId ?? this.deletedTicketId),
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [
        status,
        ticket,
        comments,
        history,
        errorMessage,
        successMessage,
        isRatingSubmitting,
        isCommentSubmitting,
        isDeleting,
        deletedTicketId,
        isOffline,
      ];
}
