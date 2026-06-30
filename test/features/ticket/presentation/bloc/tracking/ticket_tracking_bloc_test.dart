import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_event.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_state.dart';

void main() {
  group('TicketTrackingBloc', () {
    blocTest<TicketTrackingBloc, TicketTrackingState>(
      'loads tracking timeline with stable ordering and actor mapping',
      build: () => _buildBloc(_TrackingRepository(
        history: [
          _history(
            id: '2',
            createdAt: DateTime.parse('2026-06-30T10:02:00Z'),
            oldStatus: 'open',
            newStatus: 'in_progress',
            changedByName: 'Helpdesk',
          ),
          _history(
            id: '1',
            createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
            changedByName: 'Reporter',
            oldStatus: null,
            newStatus: 'open',
          ),
        ],
      )),
      act: (bloc) => bloc.add(const LoadTicketTrackingRequested('ticket-1')),
      expect: () => [
        isA<TicketTrackingState>().having(
          (state) => state.status,
          'status',
          TicketTrackingStatus.loading,
        ),
        isA<TicketTrackingState>().having(
          (state) => state.ticket?.id,
          'ticket',
          'ticket-1',
        ),
        isA<TicketTrackingState>()
            .having(
              (state) => state.status,
              'status',
              TicketTrackingStatus.loaded,
            )
            .having(
              (state) => state.items.map((item) => item.id).toList(),
              'item ids',
              ['1', '2'],
            )
            .having(
              (state) => state.items.last.actorName,
              'last actor',
              'Helpdesk',
            )
            .having(
              (state) => state.items.last.isCurrent,
              'current marker',
              isTrue,
            ),
      ],
    );

    blocTest<TicketTrackingBloc, TicketTrackingState>(
      'returns empty when no tracking history exists',
      build: () => _buildBloc(_TrackingRepository(history: const [])),
      act: (bloc) => bloc.add(const LoadTicketTrackingRequested('ticket-1')),
      expect: () => [
        isA<TicketTrackingState>(),
        isA<TicketTrackingState>(),
        isA<TicketTrackingState>().having(
          (state) => state.status,
          'status',
          TicketTrackingStatus.empty,
        ),
      ],
    );

    blocTest<TicketTrackingBloc, TicketTrackingState>(
      'maps unauthorized detail access for direct route',
      build: () => _buildBloc(_TrackingRepository(
        detailFailure: const TicketOperationFailure(
          type: TicketFailureType.authorization,
          message: 'Akses ditolak.',
        ),
      )),
      act: (bloc) => bloc.add(const LoadTicketTrackingRequested('ticket-1')),
      expect: () => [
        isA<TicketTrackingState>(),
        isA<TicketTrackingState>().having(
          (state) => state.status,
          'status',
          TicketTrackingStatus.unauthorized,
        ),
      ],
    );

    blocTest<TicketTrackingBloc, TicketTrackingState>(
      'maps not found detail access',
      build: () => _buildBloc(_TrackingRepository(
        detailFailure: const TicketOperationFailure(
          type: TicketFailureType.notFound,
          message: 'Tiket tidak ditemukan.',
        ),
      )),
      act: (bloc) => bloc.add(const LoadTicketTrackingRequested('missing')),
      expect: () => [
        isA<TicketTrackingState>(),
        isA<TicketTrackingState>().having(
          (state) => state.status,
          'status',
          TicketTrackingStatus.notFound,
        ),
      ],
    );

    blocTest<TicketTrackingBloc, TicketTrackingState>(
      'retries after transient history failure',
      build: () => _buildBloc(_TrackingRepository(
        failHistoryOnce: true,
        history: [
          _history(
            id: '1',
            createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
            changedByName: 'Reporter',
            oldStatus: null,
            newStatus: 'open',
          ),
        ],
      )),
      act: (bloc) async {
        bloc.add(const LoadTicketTrackingRequested('ticket-1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const LoadTicketTrackingRequested('ticket-1'));
      },
      verify: (bloc) {
        expect(bloc.state.status, TicketTrackingStatus.loaded);
        expect(bloc.state.items, hasLength(1));
      },
    );

    blocTest<TicketTrackingBloc, TicketTrackingState>(
      'reset clears tracking state and ignores stale load result',
      build: () => _buildBloc(_TrackingRepository(
        detailCompleter: Completer<TicketEntity>(),
      )),
      act: (bloc) async {
        final repository =
            bloc.getTicketDetailUseCase.repository as _TrackingRepository;
        bloc.add(const LoadTicketTrackingRequested('ticket-1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const ResetTicketTrackingState());
        repository.detailCompleter!.complete(_ticket());
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (bloc) {
        expect(bloc.state, const TicketTrackingState());
      },
    );
  });
}

TicketTrackingBloc _buildBloc(_TrackingRepository repository) {
  return TicketTrackingBloc(
    getTicketDetailUseCase: GetTicketDetailUseCase(repository),
    getTicketHistoryUseCase: GetTicketHistoryUseCase(repository),
  );
}

TicketEntity _ticket() {
  return TicketEntity(
    id: 'ticket-1',
    title: 'Printer error',
    description: 'Printer lantai 2 tidak dapat mencetak.',
    status: TicketStatus.open,
    category: 'hardware',
    createdAt: DateTime.parse('2026-06-30T09:59:00Z'),
    userId: 'user-1',
  );
}

TicketHistoryEntity _history({
  required String id,
  required DateTime createdAt,
  required String? oldStatus,
  required String? newStatus,
  required String changedByName,
}) {
  return TicketHistoryEntity(
    id: id,
    ticketId: 'ticket-1',
    activityType: oldStatus == null ? 'ticket_created' : 'status_changed',
    oldStatus: oldStatus,
    newStatus: newStatus,
    changedBy: 'actor-$id',
    changedByName: changedByName,
    description: null,
    createdAt: createdAt,
  );
}

class _TrackingRepository implements TicketRepository {
  final Failure? detailFailure;
  final List<TicketHistoryEntity> history;
  final bool failHistoryOnce;
  final Completer<TicketEntity>? detailCompleter;
  int _historyCalls = 0;

  _TrackingRepository({
    this.detailFailure,
    this.history = const [],
    this.failHistoryOnce = false,
    this.detailCompleter,
  });

  @override
  Future<Either<Failure, TicketEntity>> getTicketDetail(String ticketId) async {
    if (detailFailure != null) {
      return Left(detailFailure!);
    }
    if (detailCompleter != null) {
      return Right(await detailCompleter!.future);
    }
    return Right(_ticket());
  }

  @override
  Future<Either<Failure, List<TicketHistoryEntity>>> getTicketHistory(
      String ticketId) async {
    _historyCalls++;
    if (failHistoryOnce && _historyCalls == 1) {
      return const Left(ServerFailure(message: 'temporary failure', code: 500));
    }
    return Right(history);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
