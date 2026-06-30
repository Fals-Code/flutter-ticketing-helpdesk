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
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/watch_ticket_comments_usecase.dart';
import 'package:uts/features/ticket/domain/usecases/watch_ticket_detail_usecase.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_event.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TicketDetailBloc', () {
    blocTest<TicketDetailBloc, TicketDetailState>(
      'loads detail and comments successfully',
      build: () {
        final repository = _FakeDetailRepository();
        return _buildBloc(repository);
      },
      act: (bloc) => bloc.add(const FetchTicketDetailRequested('ticket-1')),
      expect: () => [
        isA<TicketDetailState>().having(
            (state) => state.status, 'status', TicketDetailStatus.loading),
        isA<TicketDetailState>()
            .having(
                (state) => state.status, 'status', TicketDetailStatus.loaded)
            .having((state) => state.ticket?.id, 'ticket id', 'ticket-1')
            .having((state) => state.comments.length, 'comment count', 1),
      ],
    );

    blocTest<TicketDetailBloc, TicketDetailState>(
      'maps not found failure to notFound status',
      build: () {
        final repository = _FakeDetailRepository(
          detailFailure: const TicketOperationFailure(
            type: TicketFailureType.notFound,
            message: 'Tiket tidak ditemukan.',
          ),
        );
        return _buildBloc(repository);
      },
      act: (bloc) => bloc.add(const FetchTicketDetailRequested('missing')),
      expect: () => [
        isA<TicketDetailState>(),
        isA<TicketDetailState>().having(
          (state) => state.status,
          'status',
          TicketDetailStatus.notFound,
        ),
      ],
    );

    blocTest<TicketDetailBloc, TicketDetailState>(
      'blocks duplicate comment submit while request in flight',
      build: () {
        final repository = _FakeDetailRepository(
          addCommentCompleter: Completer<void>(),
        );
        return _buildBloc(repository);
      },
      seed: () => TicketDetailState(
        status: TicketDetailStatus.loaded,
        ticket: _ticket(),
      ),
      act: (bloc) async {
        bloc.add(
            const AddCommentRequested(ticketId: 'ticket-1', message: 'Halo'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(
          const AddCommentRequested(ticketId: 'ticket-1', message: 'Halo lagi'),
        );
      },
      verify: (bloc) {
        final repository =
            (bloc.addCommentUseCase.repository as _FakeDetailRepository);
        expect(repository.addCommentCallCount, 1);
      },
    );

    blocTest<TicketDetailBloc, TicketDetailState>(
      'deduplicates realtime comments and keeps ordering stable',
      build: () => _buildBloc(_FakeDetailRepository()),
      seed: () => TicketDetailState(
        status: TicketDetailStatus.loaded,
        ticket: _ticket(),
      ),
      act: (bloc) => bloc.add(CommentStreamUpdated([
        _comment('2', 'later', DateTime.parse('2026-06-30T10:02:00Z')),
        _comment('1', 'first', DateTime.parse('2026-06-30T10:01:00Z')),
        _comment('2', 'later', DateTime.parse('2026-06-30T10:02:00Z')),
      ])),
      expect: () => [
        isA<TicketDetailState>().having(
          (state) => state.comments.map((comment) => comment.id).toList(),
          'comment ids',
          ['1', '2'],
        ),
      ],
    );
  });
}

TicketDetailBloc _buildBloc(_FakeDetailRepository repository) {
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
    localDataSource: _FakeTicketLocalDataSource(),
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
    userId: 'user-1',
  );
}

CommentEntity _comment(String id, String message, DateTime createdAt) {
  return CommentEntity(
    id: id,
    ticketId: 'ticket-1',
    userId: 'user-1',
    userName: 'User',
    userRole: 'user',
    message: message,
    createdAt: createdAt,
  );
}

class _FakeDetailRepository implements TicketRepository {
  final Failure? detailFailure;
  final Completer<void>? addCommentCompleter;
  int addCommentCallCount = 0;

  _FakeDetailRepository({
    this.detailFailure,
    this.addCommentCompleter,
  });

  @override
  Future<Either<Failure, TicketEntity>> getTicketDetail(String ticketId) async {
    if (detailFailure != null) {
      return Left(detailFailure!);
    }
    return Right(_ticket());
  }

  @override
  Future<Either<Failure, List<CommentEntity>>> getTicketComments(
      String ticketId) async {
    return Right([
      _comment('1', 'first', DateTime.parse('2026-06-30T10:01:00Z')),
    ]);
  }

  @override
  Future<Either<Failure, CommentEntity>> addComment({
    required String ticketId,
    required String message,
  }) async {
    addCommentCallCount++;
    if (addCommentCompleter != null) {
      await addCommentCompleter!.future;
    }
    return Right(
        _comment('2', message, DateTime.parse('2026-06-30T10:02:00Z')));
  }

  @override
  Stream<TicketEntity?> watchTicketDetail(String ticketId) {
    return Stream.value(_ticket());
  }

  @override
  Stream<List<CommentEntity>> watchTicketComments(String ticketId) {
    return const Stream<List<CommentEntity>>.empty();
  }

  @override
  Future<Either<Failure, List<TicketHistoryEntity>>> getTicketHistory(
      String ticketId) async {
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTicketLocalDataSource implements TicketLocalDataSource {
  @override
  Future<void> cacheTicketDetail(TicketModel ticket) async {}

  @override
  Future<void> cacheTickets(List<TicketModel> tickets) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<void> removeCachedTicketDetail(String ticketId) async {}

  @override
  Future<TicketModel?> getCachedTicketDetail(String ticketId) async => null;

  @override
  Future<List<TicketModel>> getCachedTickets() async => const [];
}
