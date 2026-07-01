import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_event.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_state.dart';
import 'package:uts/features/ticket/presentation/pages/ticket_tracking_page.dart';
import 'package:uts/features/ticket/domain/services/ticket_tracking_timeline_builder.dart';

class MockTicketTrackingBloc
    extends MockBloc<TicketTrackingEvent, TicketTrackingState>
    implements TicketTrackingBloc {}

class TicketTrackingEventFake extends Fake implements TicketTrackingEvent {}

void main() {
  late MockTicketTrackingBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(TicketTrackingEventFake());
  });

  setUp(() {
    mockBloc = MockTicketTrackingBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<TicketTrackingBloc>.value(
        value: mockBloc,
        child: const TicketTrackingPage(ticketId: 'ticket-1'),
      ),
    );
  }

  final tTicket = TicketEntity(
    id: 'ticket-1',
    title: 'Test Ticket',
    description: 'Description',
    status: TicketStatus.open,
    category: 'Bug',
    createdAt: DateTime.now(),
    userId: 'user-1',
    userName: 'John Doe',
  );

  final viewData =
      TicketTrackingTimelineBuilder().build(ticket: tTicket, history: []);

  testWidgets('Tiket dibuat selalu terlihat', (tester) async {
    when(() => mockBloc.state).thenReturn(TicketTrackingState(
      status: TicketTrackingStatus.loaded,
      ticket: tTicket,
      viewData: viewData,
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('Tiket dibuat'), findsOneWidget);
    expect(find.text('John Doe'), findsWidgets);
  });

  testWidgets('Closed ticket menampilkan Ditutup', (tester) async {
    final closedTicket = TicketEntity(
      id: 'ticket-1',
      title: 'Test Ticket',
      description: 'Description',
      status: TicketStatus.closed,
      category: 'Bug',
      createdAt: DateTime.now(),
      userId: 'user-1',
    );
    final closedViewData = TicketTrackingTimelineBuilder()
        .build(ticket: closedTicket, history: []);

    when(() => mockBloc.state).thenReturn(TicketTrackingState(
      status: TicketTrackingStatus.loaded,
      ticket: closedTicket,
      viewData: closedViewData,
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('Ditutup'), findsWidgets); // Summary card + Progress
  });

  testWidgets('Retry dapat ditekan', (tester) async {
    when(() => mockBloc.state).thenReturn(const TicketTrackingState(
      status: TicketTrackingStatus.failure,
      errorMessage: 'Error',
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.tap(find.text('Coba Lagi'));

    verify(() => mockBloc.add(any(that: isA<LoadTicketTrackingRequested>())))
        .called(1);
  });
}
