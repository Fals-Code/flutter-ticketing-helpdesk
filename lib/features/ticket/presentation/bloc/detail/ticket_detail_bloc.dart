import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/core/services/connectivity_service.dart';
import 'package:uts/features/ticket/data/datasources/ticket_local_data_source.dart';
import 'package:uts/features/ticket/data/models/ticket_model.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/services/comment_collection_utils.dart';
import 'package:uts/features/ticket/domain/services/ticket_tracking_timeline_builder.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/watch_ticket_comments_usecase.dart';
import 'package:uts/features/ticket/domain/usecases/watch_ticket_detail_usecase.dart';

import 'ticket_detail_event.dart';
import 'ticket_detail_state.dart';

class TicketDetailBloc extends Bloc<TicketDetailEvent, TicketDetailState> {
  final GetTicketDetailUseCase getTicketDetailUseCase;
  final GetTicketCommentsUseCase getTicketCommentsUseCase;
  final AddCommentUseCase addCommentUseCase;
  final DeleteTicketUseCase deleteTicketUseCase;
  final UpdateTicketStatusUseCase updateTicketStatusUseCase;
  final AssignTicketUseCase assignTicketUseCase;
  final GetTicketHistoryUseCase getTicketHistoryUseCase;
  final WatchTicketDetailUseCase watchTicketDetailUseCase;
  final WatchTicketCommentsUseCase watchTicketCommentsUseCase;
  final SubmitRatingUseCase submitRatingUseCase;
  final TicketLocalDataSource localDataSource;
  final ConnectivityService? connectivityService;
  final Stream<ConnectionStatus>? connectivityOverride;
  final TicketTrackingTimelineBuilder _trackingBuilder =
      const TicketTrackingTimelineBuilder();

  StreamSubscription<TicketEntity?>? _detailSubscription;
  StreamSubscription<List<CommentEntity>>? _commentSubscription;
  StreamSubscription<ConnectionStatus>? _connectivitySubscription;
  int _detailGeneration = 0;
  int _commentGeneration = 0;
  int _detailRequestGeneration = 0;
  int _historyRequestGeneration = 0;
  int _mutationGeneration = 0;

  TicketDetailBloc({
    required this.getTicketDetailUseCase,
    required this.getTicketCommentsUseCase,
    required this.addCommentUseCase,
    required this.deleteTicketUseCase,
    required this.updateTicketStatusUseCase,
    required this.assignTicketUseCase,
    required this.getTicketHistoryUseCase,
    required this.watchTicketDetailUseCase,
    required this.watchTicketCommentsUseCase,
    required this.submitRatingUseCase,
    required this.localDataSource,
    this.connectivityService,
    this.connectivityOverride,
  }) : super(const TicketDetailState()) {
    on<FetchTicketDetailRequested>(_onFetchDetail);
    on<StartTicketDetailSubscription>(_onStartDetailSubscription);
    on<TicketDetailStreamUpdated>(_onTicketDetailStreamUpdated);
    on<UpdateTicketStatusRequested>(_onUpdateStatus);
    on<AssignTicketRequested>(_onAssignTicket);
    on<AddCommentRequested>(_onAddComment);
    on<DeleteTicketRequested>(_onDeleteTicket);
    on<SubmitRatingRequested>(_onSubmitRating);
    on<FetchTicketActivitiesRequested>(_onFetchActivities);
    on<StartTicketCommentsSubscription>(_onStartCommentSubscription);
    on<CommentStreamUpdated>(_onCommentStreamUpdated);
    on<ResetTicketDetailState>(_onResetState);

    _connectivitySubscription = (connectivityOverride ??
            connectivityService?.connectionStream ??
            const Stream<ConnectionStatus>.empty())
        .listen((status) {
      if (!isClosed &&
          status == ConnectionStatus.online &&
          state.ticket != null) {
        add(FetchTicketDetailRequested(state.ticket!.id));
      }
    });
  }

  Future<void> _onFetchDetail(
    FetchTicketDetailRequested event,
    Emitter<TicketDetailState> emit,
  ) async {
    _detailRequestGeneration++;
    final requestGeneration = _detailRequestGeneration;

    emit(
      state.copyWith(
        status: state.ticket == null
            ? TicketDetailStatus.loading
            : TicketDetailStatus.refreshing,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await getTicketDetailUseCase(event.ticketId);
    if (requestGeneration != _detailRequestGeneration || isClosed) {
      return;
    }

    await result.fold(
      (failure) async {
        final cachedTicket =
            await localDataSource.getCachedTicketDetail(event.ticketId);
        if (cachedTicket != null) {
          emit(
            state.copyWith(
              status: TicketDetailStatus.loaded,
              ticket: cachedTicket.toEntity(),
              isOffline: true,
              successMessage: 'Menampilkan data dari cache (Offline)',
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            status: _statusFromFailure(failure),
            errorMessage: failure.message,
            clearTicket: true,
          ),
        );
      },
      (ticket) async {
        final commentsResult = await getTicketCommentsUseCase(event.ticketId);
        if (requestGeneration != _detailRequestGeneration || isClosed) {
          return;
        }
        final comments = commentsResult.getOrElse(() => state.comments);
        await localDataSource.cacheTicketDetail(TicketModel.fromEntity(ticket));

        final historyResult = await getTicketHistoryUseCase(event.ticketId);
        final history = historyResult.getOrElse(() => []);

        final trackingViewData = _trackingBuilder.build(
          ticket: ticket,
          history: history,
        );

        emit(
          state.copyWith(
            status: TicketDetailStatus.loaded,
            ticket: ticket,
            comments: deduplicateAndSortComments(comments),
            history: history,
            trackingViewData: trackingViewData,
            isOffline: false,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  Future<void> _onStartDetailSubscription(
    StartTicketDetailSubscription event,
    Emitter<TicketDetailState> emit,
  ) async {
    _detailGeneration++;
    final generation = _detailGeneration;

    final previous = _detailSubscription;
    _detailSubscription = null;
    await previous?.cancel();

    if (isClosed || generation != _detailGeneration) {
      return;
    }

    _detailSubscription = watchTicketDetailUseCase(event.ticketId).listen(
      (ticket) {
        if (!isClosed && generation == _detailGeneration) {
          add(TicketDetailStreamUpdated(ticket: ticket));
        }
      },
    );
  }

  void _onTicketDetailStreamUpdated(
    TicketDetailStreamUpdated event,
    Emitter<TicketDetailState> emit,
  ) {
    if (event.ticket == null) {
      emit(
        state.copyWith(
          status: TicketDetailStatus.notFound,
          errorMessage: 'Tiket tidak ditemukan.',
          clearTicket: true,
        ),
      );
      return;
    }

    final mergedTicket = _mergeTicketDetail(
      previous: state.ticket,
      incoming: event.ticket!,
    );

    final trackingViewData = _trackingBuilder.build(
      ticket: mergedTicket,
      history: state.history,
    );

    emit(
      state.copyWith(
        status: TicketDetailStatus.loaded,
        ticket: mergedTicket,
        trackingViewData: trackingViewData,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _onUpdateStatus(
    UpdateTicketStatusRequested event,
    Emitter<TicketDetailState> emit,
  ) async {
    emit(state.copyWith(status: TicketDetailStatus.refreshing));
    final result = await updateTicketStatusUseCase(
      UpdateStatusParams(ticketId: event.ticketId, status: event.status),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: _statusFromFailure(failure),
          errorMessage: failure.message,
        ),
      ),
      (ticket) {
        final mergedTicket = _mergeTicketDetail(
          previous: state.ticket,
          incoming: ticket,
        );
        final trackingViewData = _trackingBuilder.build(
          ticket: mergedTicket,
          history: state.history,
        );
        emit(
          state.copyWith(
            status: TicketDetailStatus.loaded,
            ticket: mergedTicket,
            trackingViewData: trackingViewData,
            successMessage: 'Status tiket diperbarui',
          ),
        );
      },
    );
  }

  Future<void> _onAssignTicket(
    AssignTicketRequested event,
    Emitter<TicketDetailState> emit,
  ) async {
    emit(state.copyWith(status: TicketDetailStatus.refreshing));
    final result = await assignTicketUseCase(
      AssignTicketParams(
        ticketId: event.ticketId,
        technicianId: event.technicianId,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: _statusFromFailure(failure),
          errorMessage: failure.message,
        ),
      ),
      (ticket) {
        final mergedTicket = _mergeTicketDetail(
          previous: state.ticket,
          incoming: ticket,
        );
        final trackingViewData = _trackingBuilder.build(
          ticket: mergedTicket,
          history: state.history,
        );
        emit(
          state.copyWith(
            status: TicketDetailStatus.loaded,
            ticket: mergedTicket,
            trackingViewData: trackingViewData,
            successMessage: 'Tiket berhasil didelegasikan',
          ),
        );
      },
    );
  }

  Future<void> _onAddComment(
    AddCommentRequested event,
    Emitter<TicketDetailState> emit,
  ) async {
    _mutationGeneration++;
    final mutationGeneration = _mutationGeneration;

    if (state.isCommentSubmitting) {
      emit(
          state.copyWith(errorMessage: 'Pengiriman komentar sedang berjalan.'));
      return;
    }

    emit(
      state.copyWith(
        isCommentSubmitting: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearDeletedTicketId: true,
      ),
    );

    final result = await addCommentUseCase(
      AddCommentParams(ticketId: event.ticketId, message: event.message),
    );
    if (mutationGeneration != _mutationGeneration || isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          isCommentSubmitting: false,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isCommentSubmitting: false,
          successMessage: 'Tanggapan berhasil dikirim',
        ),
      ),
    );
  }

  Future<void> _onDeleteTicket(
    DeleteTicketRequested event,
    Emitter<TicketDetailState> emit,
  ) async {
    _mutationGeneration++;
    final mutationGeneration = _mutationGeneration;

    if (state.isDeleting) {
      emit(state.copyWith(
        errorMessage: 'Penghapusan tiket sedang berjalan.',
      ));
      return;
    }

    emit(
      state.copyWith(
        isDeleting: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearDeletedTicketId: true,
      ),
    );

    final result = await deleteTicketUseCase(
      DeleteTicketParams(
        ticketId: event.ticketId,
        reason: event.reason,
      ),
    );
    if (mutationGeneration != _mutationGeneration || isClosed) {
      return;
    }

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            isDeleting: false,
            errorMessage: failure.message,
          ),
        );
      },
      (ticketId) async {
        await _cancelTicketSubscriptions();
        await localDataSource.removeCachedTicketDetail(ticketId);
        emit(
          state.copyWith(
            isDeleting: false,
            deletedTicketId: ticketId,
            successMessage: 'Tiket berhasil dihapus.',
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  Future<void> _onSubmitRating(
    SubmitRatingRequested event,
    Emitter<TicketDetailState> emit,
  ) async {
    _mutationGeneration++;
    final mutationGeneration = _mutationGeneration;

    emit(state.copyWith(isRatingSubmitting: true));
    final result = await submitRatingUseCase(
      SubmitRatingParams(
        ticketId: event.ticketId,
        rating: event.rating,
        feedback: event.feedback,
      ),
    );
    if (mutationGeneration != _mutationGeneration || isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          isRatingSubmitting: false,
          errorMessage: failure.message,
        ),
      ),
      (ticket) {
        final mergedTicket = _mergeTicketDetail(
          previous: state.ticket,
          incoming: ticket,
        );
        final trackingViewData = _trackingBuilder.build(
          ticket: mergedTicket,
          history: state.history,
        );
        emit(
          state.copyWith(
            isRatingSubmitting: false,
            ticket: mergedTicket,
            trackingViewData: trackingViewData,
            successMessage: 'Terima kasih atas penilaian Anda!',
          ),
        );
      },
    );
  }

  Future<void> _onFetchActivities(
    FetchTicketActivitiesRequested event,
    Emitter<TicketDetailState> emit,
  ) async {
    _historyRequestGeneration++;
    final requestGeneration = _historyRequestGeneration;

    final result = await getTicketHistoryUseCase(event.ticketId);
    if (requestGeneration != _historyRequestGeneration || isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (history) {
        final trackingViewData = state.ticket != null
            ? _trackingBuilder.build(
                ticket: state.ticket!,
                history: history,
              )
            : null;
        emit(
          state.copyWith(
            history: history,
            trackingViewData: trackingViewData,
          ),
        );
      },
    );
  }

  Future<void> _onStartCommentSubscription(
    StartTicketCommentsSubscription event,
    Emitter<TicketDetailState> emit,
  ) async {
    _commentGeneration++;
    final generation = _commentGeneration;

    final previous = _commentSubscription;
    _commentSubscription = null;
    await previous?.cancel();

    if (isClosed || generation != _commentGeneration) {
      return;
    }

    _commentSubscription = watchTicketCommentsUseCase(event.ticketId).listen(
      (comments) {
        if (!isClosed && generation == _commentGeneration) {
          add(CommentStreamUpdated(comments));
        }
      },
    );
  }

  void _onCommentStreamUpdated(
    CommentStreamUpdated event,
    Emitter<TicketDetailState> emit,
  ) {
    emit(
      state.copyWith(
        comments: deduplicateAndSortComments(event.comments),
      ),
    );
  }

  Future<void> _onResetState(
    ResetTicketDetailState event,
    Emitter<TicketDetailState> emit,
  ) async {
    _detailRequestGeneration++;
    _historyRequestGeneration++;
    _mutationGeneration++;
    await _cancelTicketSubscriptions();
    emit(const TicketDetailState());
  }

  Future<void> _cancelTicketSubscriptions() async {
    _detailGeneration++;
    _commentGeneration++;

    final detailSubscription = _detailSubscription;
    final commentSubscription = _commentSubscription;
    _detailSubscription = null;
    _commentSubscription = null;

    await detailSubscription?.cancel();
    await commentSubscription?.cancel();
  }

  TicketDetailStatus _statusFromFailure(Failure failure) {
    if (failure is TicketOperationFailure) {
      return switch (failure.type) {
        TicketFailureType.authorization ||
        TicketFailureType.authentication =>
          TicketDetailStatus.unauthorized,
        TicketFailureType.notFound => TicketDetailStatus.notFound,
        _ => TicketDetailStatus.failure,
      };
    }

    if (failure.code == 401 || failure.code == 403) {
      return TicketDetailStatus.unauthorized;
    }

    if (failure.code == 404) {
      return TicketDetailStatus.notFound;
    }

    return TicketDetailStatus.failure;
  }

  TicketEntity _mergeTicketDetail({
    required TicketEntity? previous,
    required TicketEntity incoming,
  }) {
    if (previous == null) {
      return incoming;
    }

    return TicketEntity(
      id: incoming.id,
      title: incoming.title,
      description: incoming.description,
      status: incoming.status,
      category: incoming.category,
      priority: incoming.priority ?? previous.priority,
      createdAt: incoming.createdAt,
      updatedAt: incoming.updatedAt,
      userId: incoming.userId,
      userName: incoming.userName ?? previous.userName,
      assignedTo: incoming.assignedTo,
      assignedToName: incoming.assignedToName ?? previous.assignedToName,
      attachments: incoming.attachments.isNotEmpty
          ? incoming.attachments
          : previous.attachments,
      imageUrls: incoming.imageUrls.isNotEmpty
          ? incoming.imageUrls
          : previous.imageUrls,
      rating: incoming.rating ?? previous.rating,
      ratingFeedback: incoming.ratingFeedback ?? previous.ratingFeedback,
    );
  }

  @override
  Future<void> close() async {
    await _cancelTicketSubscriptions();
    final connectivitySubscription = _connectivitySubscription;
    _connectivitySubscription = null;

    await connectivitySubscription?.cancel();
    await super.close();
  }
}
