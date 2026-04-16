import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/watch_ticket_comments_usecase.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import 'ticket_detail_event.dart';
import 'ticket_detail_state.dart';

class TicketDetailBloc extends Bloc<TicketDetailEvent, TicketDetailState> {
  final GetTicketDetailUseCase getTicketDetailUseCase;
  final GetTicketCommentsUseCase getTicketCommentsUseCase;
  final AddCommentUseCase addCommentUseCase;
  final UpdateTicketStatusUseCase updateTicketStatusUseCase;
  final AssignTicketUseCase assignTicketUseCase;
  final GetTicketHistoryUseCase getTicketHistoryUseCase;
  final WatchTicketCommentsUseCase watchTicketCommentsUseCase;
  final SubmitRatingUseCase submitRatingUseCase;
  StreamSubscription? _commentSubscription;

  TicketDetailBloc({
    required this.getTicketDetailUseCase,
    required this.getTicketCommentsUseCase,
    required this.addCommentUseCase,
    required this.updateTicketStatusUseCase,
    required this.assignTicketUseCase,
    required this.getTicketHistoryUseCase,
    required this.watchTicketCommentsUseCase,
    required this.submitRatingUseCase,
  }) : super(const TicketDetailState()) {
    on<FetchTicketDetailRequested>(_onFetchDetail);
    on<UpdateTicketStatusRequested>(_onUpdateStatus);
    on<AssignTicketRequested>(_onAssignTicket);
    on<AddCommentRequested>(_onAddComment);
    on<SubmitRatingRequested>(_onSubmitRating);
    on<FetchTicketActivitiesRequested>(_onFetchActivities);
    on<StartTicketCommentsSubscription>(_onStartCommentSubscription);
    on<CommentStreamUpdated>(_onCommentStreamUpdated);
    on<ResetTicketDetailState>(_onResetState);
  }

  Future<void> _onFetchDetail(FetchTicketDetailRequested event, Emitter<TicketDetailState> emit) async {
    emit(state.copyWith(isLoading: true, comments: []));
    final result = await getTicketDetailUseCase(event.ticketId);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (ticket) => emit(state.copyWith(isLoading: false, ticket: ticket)),
    );
  }

  Future<void> _onUpdateStatus(UpdateTicketStatusRequested event, Emitter<TicketDetailState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await updateTicketStatusUseCase(UpdateStatusParams(ticketId: event.ticketId, status: event.status));
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (ticket) => emit(state.copyWith(isLoading: false, ticket: ticket, successMessage: 'Status tiket diperbarui')),
    );
  }

  Future<void> _onAssignTicket(AssignTicketRequested event, Emitter<TicketDetailState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await assignTicketUseCase(AssignTicketParams(ticketId: event.ticketId, technicianId: event.technicianId));
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (ticket) => emit(state.copyWith(isLoading: false, ticket: ticket, successMessage: 'Tiket berhasil didelegasikan')),
    );
  }

  Future<void> _onAddComment(AddCommentRequested event, Emitter<TicketDetailState> emit) async {
    final result = await addCommentUseCase(AddCommentParams(ticketId: event.ticketId, message: event.message));
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (comment) => emit(state.copyWith(successMessage: 'Tanggapan berhasil dikirim')),
    );
  }

  Future<void> _onSubmitRating(SubmitRatingRequested event, Emitter<TicketDetailState> emit) async {
    emit(state.copyWith(isRatingSubmitting: true));
    final result = await submitRatingUseCase(SubmitRatingParams(
      ticketId: event.ticketId,
      rating: event.rating,
      feedback: event.feedback,
    ));
    result.fold(
      (failure) => emit(state.copyWith(isRatingSubmitting: false, errorMessage: failure.message)),
      (ticket) => emit(state.copyWith(
        isRatingSubmitting: false,
        ticket: ticket,
        successMessage: 'Terima kasih atas penilaian Anda!',
      )),
    );
  }

  Future<void> _onFetchActivities(FetchTicketActivitiesRequested event, Emitter<TicketDetailState> emit) async {
    final result = await getTicketHistoryUseCase(event.ticketId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (history) => emit(state.copyWith(history: history)),
    );
  }

  void _onStartCommentSubscription(StartTicketCommentsSubscription event, Emitter<TicketDetailState> emit) {
    _commentSubscription?.cancel();
    _commentSubscription = watchTicketCommentsUseCase(event.ticketId).listen(
      (comments) => add(CommentStreamUpdated(comments)),
    );
  }

  void _onCommentStreamUpdated(CommentStreamUpdated event, Emitter<TicketDetailState> emit) {
    emit(state.copyWith(comments: List<CommentEntity>.from(event.comments)));
  }

  void _onResetState(ResetTicketDetailState event, Emitter<TicketDetailState> emit) {
    _commentSubscription?.cancel();
    emit(const TicketDetailState());
  }

  @override
  Future<void> close() {
    _commentSubscription?.cancel();
    return super.close();
  }
}
