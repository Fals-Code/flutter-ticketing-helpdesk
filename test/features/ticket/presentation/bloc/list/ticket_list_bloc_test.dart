import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/core/services/connectivity_service.dart';
import 'package:uts/features/ticket/data/datasources/ticket_local_data_source.dart';
import 'package:uts/features/ticket/data/models/ticket_model.dart';
import 'package:uts/features/ticket/domain/entities/create_ticket_params.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_admin_usecases.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/domain/value_objects/paginated_result.dart';
import 'package:uts/features/ticket/domain/value_objects/ticket_query.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TicketListBloc', () {
    blocTest<TicketListBloc, TicketListState>(
      'loads initial user page successfully',
      build: () {
        final repository = _FakeTicketRepository(
          userPageHandler: (query) async => PaginatedResult<TicketEntity>(
            items: [_ticket('1')],
            hasMore: false,
          ),
        );
        return _buildBloc(repository);
      },
      act: (bloc) => bloc.add(const FetchTicketsRequested(page: 0, limit: 10)),
      expect: () => [
        isA<TicketListState>()
            .having((state) => state.isInitialLoading, 'loading', isTrue),
        isA<TicketListState>()
            .having((state) => state.isInitialLoading, 'loading', isFalse)
            .having((state) => state.tickets.length, 'ticket count', 1)
            .having((state) => state.hasMore, 'hasMore', isFalse),
      ],
    );

    blocTest<TicketListBloc, TicketListState>(
      'deduplicates tickets across pages',
      build: () {
        final repository = _FakeTicketRepository(
          userPageHandler: (query) async {
            if (query.page == 0) {
              return PaginatedResult<TicketEntity>(
                items: [_ticket('1'), _ticket('2')],
                hasMore: true,
              );
            }
            return PaginatedResult<TicketEntity>(
              items: [_ticket('2'), _ticket('3')],
              hasMore: false,
            );
          },
        );
        return _buildBloc(repository);
      },
      act: (bloc) async {
        bloc.add(const FetchTicketsRequested(page: 0, limit: 10));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const FetchTicketsRequested(page: 1, limit: 10));
      },
      expect: () => [
        isA<TicketListState>()
            .having((state) => state.isInitialLoading, 'loading', isTrue),
        isA<TicketListState>().having(
            (state) => state.tickets.map((ticket) => ticket.id).toList(),
            'ids',
            ['2', '1']),
        isA<TicketListState>()
            .having((state) => state.isLoadingMore, 'loadingMore', isTrue),
        isA<TicketListState>().having(
            (state) => state.tickets.map((ticket) => ticket.id).toList(),
            'ids',
            ['3', '2', '1']),
      ],
    );

    blocTest<TicketListBloc, TicketListState>(
      'keeps items when load-more fails',
      build: () {
        final repository = _FakeTicketRepository(
          userPageHandler: (query) async {
            if (query.page == 0) {
              return PaginatedResult<TicketEntity>(
                items: [_ticket('1')],
                hasMore: true,
              );
            }
            throw const TicketOperationFailure(
              type: TicketFailureType.network,
              message: 'network error',
            );
          },
        );
        return _buildBloc(repository);
      },
      act: (bloc) async {
        bloc.add(const FetchTicketsRequested(page: 0, limit: 10));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const FetchTicketsRequested(page: 1, limit: 10));
      },
      expect: () => [
        isA<TicketListState>(),
        isA<TicketListState>()
            .having((state) => state.tickets.length, 'count', 1),
        isA<TicketListState>(),
        isA<TicketListState>()
            .having((state) => state.tickets.length, 'count', 1)
            .having((state) => state.loadMoreErrorMessage, 'loadMoreError',
                'network error'),
      ],
    );

    blocTest<TicketListBloc, TicketListState>(
      'ignores stale response after search changes',
      build: () {
        final slow = Completer<PaginatedResult<TicketEntity>>();
        final repository = _FakeTicketRepository(
          userPageHandler: (query) {
            if ((query.search ?? '').isEmpty) {
              return slow.future;
            }
            return Future.value(PaginatedResult<TicketEntity>(
              items: [_ticket('search', title: 'Printer search result')],
              hasMore: false,
            ));
          },
        );
        return _buildBloc(repository);
      },
      act: (bloc) async {
        bloc.add(const FetchTicketsRequested(page: 0, limit: 10));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SearchTicketsRequested('printer'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (bloc) {
        expect(bloc.state.tickets.single.id, 'search');
      },
    );

    blocTest<TicketListBloc, TicketListState>(
      'removes deleted ticket from local list state',
      build: () => _buildBloc(_FakeTicketRepository()),
      seed: () => TicketListState.initial().copyWith(
        tickets: [_ticket('1'), _ticket('2')],
        allTickets: [_ticket('1'), _ticket('3')],
      ),
      act: (bloc) => bloc.add(const TicketDeletedLocally('1')),
      expect: () => [
        isA<TicketListState>().having(
            (state) => state.tickets.map((ticket) => ticket.id).toList(),
            'user ids', [
          '2'
        ]).having(
            (state) => state.allTickets.map((ticket) => ticket.id).toList(),
            'staff ids',
            ['3']),
      ],
    );

    blocTest<TicketListBloc, TicketListState>(
      'reset clears list state and ignores stale fetch result',
      build: () {
        pendingUserPageCompleter = Completer<PaginatedResult<TicketEntity>>();
        final repository = _FakeTicketRepository(
          userPageHandler: (_) => pendingUserPageCompleter!.future,
        );
        return _buildBloc(repository);
      },
      act: (bloc) async {
        bloc.add(const FetchTicketsRequested(page: 0, limit: 10));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(ResetTicketListState());
        pendingUserPageCompleter!.complete(PaginatedResult<TicketEntity>(
          items: [_ticket('late')],
          hasMore: false,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (bloc) {
        expect(bloc.state, TicketListState.initial());
      },
    );
  });
}

TicketListBloc _buildBloc(_FakeTicketRepository repository) {
  return TicketListBloc(
    getTicketsUseCase: GetTicketsUseCase(repository),
    getAllTicketsUseCase: GetAllTicketsUseCase(repository),
    watchTicketsUseCase: WatchTicketsUseCase(repository),
    createTicketUseCase: CreateTicketUseCase(repository),
    localDataSource: _FakeTicketLocalDataSource(),
    connectivityService: null,
    connectivityOverride: const Stream<ConnectionStatus>.empty(),
  );
}

Completer<PaginatedResult<TicketEntity>>? pendingUserPageCompleter;

TicketEntity _ticket(String id, {String title = 'Printer error'}) {
  return TicketEntity(
    id: id,
    title: title,
    description: 'Printer lantai 2 tidak dapat mencetak.',
    status: TicketStatus.open,
    category: 'hardware',
    createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
    updatedAt: DateTime.parse('2026-06-30T10:00:00Z'),
    userId: 'user-1',
  );
}

class _FakeTicketRepository implements TicketRepository {
  final Future<PaginatedResult<TicketEntity>> Function(TicketQuery query)?
      userPageHandler;

  _FakeTicketRepository({this.userPageHandler});

  @override
  Future<Either<Failure, PaginatedResult<TicketEntity>>> getTickets({
    required TicketQuery query,
  }) async {
    try {
      return Right(await userPageHandler!(query));
    } on Failure catch (failure) {
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<TicketEntity>>> getAllTickets({
    required TicketQuery query,
    String? assignedToId,
  }) async {
    return const Right(PaginatedResult<TicketEntity>(
      items: [],
      hasMore: false,
    ));
  }

  @override
  Stream<List<TicketEntity>> watchTickets(
      {String? userId, String? assignedToId}) {
    return const Stream<List<TicketEntity>>.empty();
  }

  @override
  Future<Either<Failure, TicketEntity>> createTicket(
    CreateTicketParams params,
  ) async {
    return Right(_ticket('created'));
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
