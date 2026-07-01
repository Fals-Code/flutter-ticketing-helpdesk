import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uts/core/error/failures.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/ticket/domain/usecases/ticket_usecases.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_event.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_state.dart';

class MockGetTicketDetailUseCase extends Mock
    implements GetTicketDetailUseCase {}

class MockGetTicketHistoryUseCase extends Mock
    implements GetTicketHistoryUseCase {}

void main() {
  late TicketTrackingBloc bloc;
  late MockGetTicketDetailUseCase mockGetTicketDetail;
  late MockGetTicketHistoryUseCase mockGetTicketHistory;

  final tTicketId = 'ticket-1';
  final tTicket = TicketEntity(
    id: tTicketId,
    title: 'Test',
    description: 'Desc',
    status: TicketStatus.open,
    category: 'Bug',
    createdAt: DateTime.now(),
    userId: 'user-1',
  );

  setUp(() {
    mockGetTicketDetail = MockGetTicketDetailUseCase();
    mockGetTicketHistory = MockGetTicketHistoryUseCase();
    bloc = TicketTrackingBloc(
      getTicketDetailUseCase: mockGetTicketDetail,
      getTicketHistoryUseCase: mockGetTicketHistory,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be empty', () {
    expect(bloc.state.status, TicketTrackingStatus.initial);
  });

  blocTest<TicketTrackingBloc, TicketTrackingState>(
    'History kosong menghasilkan loaded, bukan empty',
    build: () {
      when(() => mockGetTicketDetail(any()))
          .thenAnswer((_) async => Right(tTicket));
      when(() => mockGetTicketHistory(any()))
          .thenAnswer((_) async => const Right([]));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadTicketTrackingRequested(tTicketId)),
    expect: () => [
      const TicketTrackingState(status: TicketTrackingStatus.loading),
      isA<TicketTrackingState>()
          .having((s) => s.status, 'status', TicketTrackingStatus.loaded)
          .having((s) => s.viewData?.activityEvents.length, 'events count', 1),
    ],
  );

  blocTest<TicketTrackingBloc, TicketTrackingState>(
    'Loaded memuat created milestone',
    build: () {
      when(() => mockGetTicketDetail(any()))
          .thenAnswer((_) async => Right(tTicket));
      when(() => mockGetTicketHistory(any()))
          .thenAnswer((_) async => const Right([]));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadTicketTrackingRequested(tTicketId)),
    verify: (bloc) {
      expect(bloc.state.viewData?.lifecycleMilestones[0].title, 'Dibuat');
    },
  );

  blocTest<TicketTrackingBloc, TicketTrackingState>(
    'Unauthorized tetap unauthorized',
    build: () {
      when(() => mockGetTicketDetail(any()))
          .thenAnswer((_) async => const Left(TicketOperationFailure(
                type: TicketFailureType.authorization,
                message: 'No access',
              )));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadTicketTrackingRequested(tTicketId)),
    expect: () => [
      const TicketTrackingState(status: TicketTrackingStatus.loading),
      isA<TicketTrackingState>()
          .having((s) => s.status, 'status', TicketTrackingStatus.unauthorized)
          .having((s) => s.errorMessage, 'error message', 'No access'),
    ],
  );

  blocTest<TicketTrackingBloc, TicketTrackingState>(
    'NotFound tetap notFound',
    build: () {
      when(() => mockGetTicketDetail(any()))
          .thenAnswer((_) async => const Left(TicketOperationFailure(
                type: TicketFailureType.notFound,
                message: 'Not found',
              )));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadTicketTrackingRequested(tTicketId)),
    expect: () => [
      const TicketTrackingState(status: TicketTrackingStatus.loading),
      isA<TicketTrackingState>()
          .having((s) => s.status, 'status', TicketTrackingStatus.notFound)
          .having((s) => s.errorMessage, 'error message', 'Not found'),
    ],
  );

  blocTest<TicketTrackingBloc, TicketTrackingState>(
    'Retry bekerja',
    build: () {
      when(() => mockGetTicketDetail(any()))
          .thenAnswer((_) async => Right(tTicket));
      when(() => mockGetTicketHistory(any()))
          .thenAnswer((_) async => const Right([]));
      return bloc;
    },
    act: (bloc) async {
      bloc.add(LoadTicketTrackingRequested(tTicketId));
      await Future.delayed(Duration.zero);
      bloc.add(LoadTicketTrackingRequested(tTicketId));
    },
    expect: () => [
      isA<TicketTrackingState>()
          .having((s) => s.status, 'status', TicketTrackingStatus.loading),
      isA<TicketTrackingState>()
          .having((s) => s.status, 'status', TicketTrackingStatus.loaded),
      isA<TicketTrackingState>()
          .having((s) => s.status, 'status', TicketTrackingStatus.loading),
      isA<TicketTrackingState>()
          .having((s) => s.status, 'status', TicketTrackingStatus.loaded),
    ],
  );
}
