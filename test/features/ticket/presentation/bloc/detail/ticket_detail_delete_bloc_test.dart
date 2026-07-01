import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/core/services/connectivity_service.dart';
import 'package:uts/features/ticket/data/datasources/ticket_local_data_source.dart';
import 'package:uts/features/ticket/data/models/ticket_model.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import 'package:uts/features/ticket/domain/entities/delete_ticket_result.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/value_objects/paginated_result.dart';
import 'package:uts/features/ticket/domain/value_objects/ticket_query.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_event.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_state.dart';
import 'package:uts/features/ticket/domain/usecases/watch_ticket_comments_usecase.dart';
import 'package:uts/features/ticket/domain/usecases/watch_ticket_detail_usecase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TicketDetailBloc delete flow', () {
    blocTest<TicketDetailBloc, TicketDetailState>(
      'blocks duplicate delete submit while request is in flight',
      build: () {
        final repository =
            _DeleteRepository(deleteCompleter: Completer<void>());
        return _buildBloc(repository, _TrackingLocalDataSource());
      },
      seed: () => TicketDetailState(
        status: TicketDetailStatus.loaded,
        ticket: _ticket(),
      ),
      act: (bloc) async {
        bloc.add(const DeleteTicketRequested(
          ticketId: 'ticket-1',
          reason: 'hapus tiket',
        ));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const DeleteTicketRequested(
          ticketId: 'ticket-1',
          reason: 'hapus lagi',
        ));
      },
      verify: (bloc) {
        final repository =
            (bloc.deleteTicketUseCase.repository as _DeleteRepository);
        expect(repository.deleteCallCount, 1);
      },
    );

    blocTest<TicketDetailBloc, TicketDetailState>(
      'successful delete clears cached detail and stops detail/comment subscriptions',
      build: () {
        final repository = _DeleteRepository();
        final localDataSource = _TrackingLocalDataSource();
        return _buildBloc(repository, localDataSource);
      },
      seed: () => TicketDetailState(
        status: TicketDetailStatus.loaded,
        ticket: _ticket(),
        comments: const [],
      ),
      act: (bloc) async {
        bloc.add(const StartTicketDetailSubscription('ticket-1'));
        bloc.add(const StartTicketCommentsSubscription('ticket-1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const DeleteTicketRequested(
          ticketId: 'ticket-1',
          reason: 'hapus tiket',
        ));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      expect: () => [
        isA<TicketDetailState>().having(
          (state) => state.isDeleting,
          'isDeleting',
          isTrue,
        ),
        isA<TicketDetailState>()
            .having((state) => state.isDeleting, 'isDeleting', isFalse)
            .having((state) => state.deletedTicketId, 'deletedTicketId',
                'ticket-1'),
      ],
      verify: (bloc) {
        final repository =
            (bloc.deleteTicketUseCase.repository as _DeleteRepository);
        final localDataSource =
            bloc.localDataSource as _TrackingLocalDataSource;
        expect(repository.detailCancelCount, 1);
        expect(repository.commentCancelCount, 1);
        expect(localDataSource.removedTicketIds, ['ticket-1']);
      },
    );

    blocTest<TicketDetailBloc, TicketDetailState>(
      'delete failure keeps detail state available',
      build: () {
        final repository = _DeleteRepository(
          deleteFailure: const TicketOperationFailure(
            type: TicketFailureType.authorization,
            message: 'Tidak berhak menghapus tiket.',
          ),
        );
        return _buildBloc(repository, _TrackingLocalDataSource());
      },
      seed: () => TicketDetailState(
        status: TicketDetailStatus.loaded,
        ticket: _ticket(),
      ),
      act: (bloc) => bloc.add(const DeleteTicketRequested(
        ticketId: 'ticket-1',
        reason: 'hapus tiket',
      )),
      expect: () => [
        isA<TicketDetailState>().having(
          (state) => state.isDeleting,
          'isDeleting',
          isTrue,
        ),
        isA<TicketDetailState>()
            .having((state) => state.isDeleting, 'isDeleting', isFalse)
            .having((state) => state.ticket?.id, 'ticket', 'ticket-1')
            .having((state) => state.errorMessage, 'error',
                'Tidak berhak menghapus tiket.'),
      ],
    );

    blocTest<TicketDetailBloc, TicketDetailState>(
      'cleanup pending still clears active detail state with safe message',
      build: () {
        final repository = _DeleteRepository(
          deleteResult: const DeleteTicketResult(
            ticketId: 'ticket-1',
            cleanupStatus: DeleteTicketCleanupStatus.deletedWithCleanupPending,
            storagePaths: ['ticket/user/file.pdf'],
            failedPaths: ['ticket/user/file.pdf'],
          ),
        );
        return _buildBloc(repository, _TrackingLocalDataSource());
      },
      seed: () => TicketDetailState(
        status: TicketDetailStatus.loaded,
        ticket: _ticket(),
      ),
      act: (bloc) => bloc.add(const DeleteTicketRequested(
        ticketId: 'ticket-1',
        reason: 'hapus tiket',
      )),
      expect: () => [
        isA<TicketDetailState>(),
        isA<TicketDetailState>()
            .having((state) => state.isDeleting, 'isDeleting', isFalse)
            .having(
                (state) => state.deletedTicketId, 'deletedTicketId', 'ticket-1')
            .having(
              (state) => state.successMessage,
              'success',
              'Tiket berhasil dihapus. Cleanup lampiran akan diselesaikan.',
            ),
      ],
      verify: (bloc) {
        final localDataSource =
            bloc.localDataSource as _TrackingLocalDataSource;
        expect(localDataSource.removedTicketIds, ['ticket-1']);
      },
    );
  });
}

TicketDetailBloc _buildBloc(
  _DeleteRepository repository,
  _TrackingLocalDataSource localDataSource,
) {
  return TicketDetailBloc(
    getTicketDetailUseCase: GetTicketDetailUseCase(repository),
    getTicketCommentsUseCase: GetTicketCommentsUseCase(repository),
    addCommentUseCase: AddCommentUseCase(repository),
    deleteTicketUseCase: DeleteTicketUseCase(repository),
    updateTicketStatusUseCase: UpdateTicketStatusUseCase(repository),
    assignTicketUseCase: AssignTicketUseCase(repository),
    getTicketHistoryUseCase: GetTicketHistoryUseCase(repository),
    watchTicketDetailUseCase: WatchTicketDetailUseCase(repository),
    watchTicketCommentsUseCase: WatchTicketCommentsUseCase(repository),
    submitRatingUseCase: SubmitRatingUseCase(repository),
    localDataSource: localDataSource,
    connectivityService: null,
    connectivityOverride: const Stream<ConnectionStatus>.empty(),
  );
}

TicketEntity _ticket() {
  return TicketEntity(
    id: 'ticket-1',
    title: 'Printer error',
    description: 'Printer lantai 2 tidak dapat mencetak.',
    status: TicketStatus.open,
    category: 'hardware',
    createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
    updatedAt: DateTime.parse('2026-06-30T10:00:00Z'),
    userId: 'user-1',
  );
}

class _DeleteRepository implements TicketRepository {
  final Failure? deleteFailure;
  final DeleteTicketResult deleteResult;
  final Completer<void>? deleteCompleter;
  final StreamController<TicketEntity?> detailController =
      StreamController<TicketEntity?>.broadcast();
  final StreamController<List<CommentEntity>> commentController =
      StreamController<List<CommentEntity>>.broadcast();
  int deleteCallCount = 0;
  int detailCancelCount = 0;
  int commentCancelCount = 0;

  _DeleteRepository({
    this.deleteFailure,
    this.deleteResult = const DeleteTicketResult(
      ticketId: 'ticket-1',
      cleanupStatus: DeleteTicketCleanupStatus.deletedAndCleaned,
    ),
    this.deleteCompleter,
  });

  @override
  Future<Either<Failure, DeleteTicketResult>> deleteTicket({
    required String ticketId,
    required String reason,
  }) async {
    deleteCallCount++;
    if (deleteCompleter != null) {
      await deleteCompleter!.future;
    }
    if (deleteFailure != null) {
      return Left(deleteFailure!);
    }
    return Right(deleteResult);
  }

  @override
  Stream<TicketEntity?> watchTicketDetail(String ticketId) {
    return Stream<TicketEntity?>.multi((multi) {
      final subscription = detailController.stream.listen(
        multi.add,
        onError: multi.addError,
        onDone: multi.close,
      );
      multi.onCancel = () async {
        detailCancelCount++;
        await subscription.cancel();
      };
    });
  }

  @override
  Stream<List<CommentEntity>> watchTicketComments(String ticketId) {
    return Stream<List<CommentEntity>>.multi((multi) {
      final subscription = commentController.stream.listen(
        multi.add,
        onError: multi.addError,
        onDone: multi.close,
      );
      multi.onCancel = () async {
        commentCancelCount++;
        await subscription.cancel();
      };
    });
  }

  @override
  Future<Either<Failure, TicketEntity>> getTicketDetail(String ticketId) async {
    return Right(_ticket());
  }

  @override
  Future<Either<Failure, List<CommentEntity>>> getTicketComments(
      String ticketId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, CommentEntity>> addComment({
    required String ticketId,
    required String message,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<TicketHistoryEntity>>> getTicketHistory(
      String ticketId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, PaginatedResult<TicketEntity>>> getTickets({
    required TicketQuery query,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, PaginatedResult<TicketEntity>>> getAllTickets({
    required TicketQuery query,
    String? assignedToId,
  }) async {
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrackingLocalDataSource implements TicketLocalDataSource {
  final List<String> removedTicketIds = [];

  @override
  Future<void> cacheTicketDetail(TicketModel ticket) async {}

  @override
  Future<void> cacheTickets(List<TicketModel> tickets) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<TicketModel?> getCachedTicketDetail(String ticketId) async => null;

  @override
  Future<List<TicketModel>> getCachedTickets() async => const [];

  @override
  Future<void> removeCachedTicketDetail(String ticketId) async {
    removedTicketIds.add(ticketId);
  }
}
