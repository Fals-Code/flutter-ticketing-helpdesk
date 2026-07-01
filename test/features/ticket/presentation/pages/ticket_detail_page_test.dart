import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_tracking_view_data.dart';
import 'package:uts/features/ticket/domain/services/ticket_tracking_timeline_builder.dart';
import 'package:uts/features/ticket/domain/value_objects/ticket_query.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_event.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_state.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_state.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart';
import 'package:uts/features/ticket/presentation/pages/ticket_detail_page.dart';
import 'package:uts/features/ticket/presentation/widgets/tracking/tracking_widgets.dart';

class MockTicketDetailBloc
    extends MockBloc<TicketDetailEvent, TicketDetailState>
    implements TicketDetailBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockTicketListBloc extends MockBloc<TicketListEvent, TicketListState>
    implements TicketListBloc {}

class MockTicketStatsBloc extends MockBloc<TicketStatsEvent, TicketStatsState>
    implements TicketStatsBloc {}

void main() {
  const trackingDestinationKey = Key('tracking-destination');

  late MockTicketDetailBloc mockDetailBloc;
  late MockAuthBloc mockAuthBloc;
  late MockTicketListBloc mockListBloc;
  late MockTicketStatsBloc mockStatsBloc;

  final ticket = TicketEntity(
    id: 'ticket-1',
    title: 'Printer Error',
    description: 'Printer cannot print',
    status: TicketStatus.open,
    category: 'Hardware',
    createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
    userId: 'user-1',
    userName: 'Test User',
  );

  final trackingViewData = const TicketTrackingTimelineBuilder().build(
    ticket: ticket,
    history: const [],
  );

  setUpAll(() async {
    await initializeDateFormatting('id', null);
  });

  setUp(() {
    mockDetailBloc = MockTicketDetailBloc();
    mockAuthBloc = MockAuthBloc();
    mockListBloc = MockTicketListBloc();
    mockStatsBloc = MockTicketStatsBloc();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(
        status: AuthStatus.authenticated,
        user: AuthUser(
          id: 'user-1',
          email: 'user@test.com',
          role: UserRole.user,
        ),
      ),
    );

    when(() => mockListBloc.state).thenReturn(
      TicketListState(
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        tickets: const [],
        allTickets: const [],
        errorMessage: null,
        loadMoreErrorMessage: null,
        successMessage: null,
        hasMore: false,
        hasMoreAll: false,
        query: TicketQuery(),
        isOffline: false,
        currentPage: 1,
        allTicketsPage: 1,
        assignedToId: null,
      ),
    );

    when(() => mockStatsBloc.state).thenReturn(
      const TicketStatsState(),
    );
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/tickets/ticket-1',
      routes: [
        GoRoute(
          path: '/tickets/:id',
          builder: (context, state) {
            return TicketDetailPage(
              ticketId: state.pathParameters['id']!,
            );
          },
        ),
        GoRoute(
          name: 'ticketTracking',
          path: '/tickets/:id/tracking',
          builder: (context, state) {
            return const Scaffold(
              key: trackingDestinationKey,
              body: Center(
                child: Text('Halaman Tracking Lengkap'),
              ),
            );
          },
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<TicketDetailBloc>.value(
          value: mockDetailBloc,
        ),
        BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
        ),
        BlocProvider<TicketListBloc>.value(
          value: mockListBloc,
        ),
        BlocProvider<TicketStatsBloc>.value(
          value: mockStatsBloc,
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('TicketDetailPage lifecycle tracking', () {
    testWidgets(
      'menampilkan bagian Perjalanan Tiket ketika trackingViewData tersedia',
      (tester) async {
        when(() => mockDetailBloc.state).thenReturn(
          TicketDetailState(
            status: TicketDetailStatus.loaded,
            ticket: ticket,
            trackingViewData: trackingViewData,
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.text('PERJALANAN TIKET'), findsOneWidget);
        expect(find.byType(TicketLifecycleProgress), findsOneWidget);
        expect(find.text('Tiket dibuat'), findsWidgets);
      },
    );

    testWidgets(
      'tidak menampilkan Perjalanan Tiket ketika trackingViewData null',
      (tester) async {
        when(() => mockDetailBloc.state).thenReturn(
          TicketDetailState(
            status: TicketDetailStatus.loaded,
            ticket: ticket,
            trackingViewData: null,
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.text('PERJALANAN TIKET'), findsNothing);
        expect(find.byType(TicketLifecycleProgress), findsNothing);
        expect(find.text('Aktivitas Terbaru'), findsNothing);
      },
    );

    testWidgets(
      'menampilkan aktivitas terbaru dan tombol perjalanan lengkap',
      (tester) async {
        when(() => mockDetailBloc.state).thenReturn(
          TicketDetailState(
            status: TicketDetailStatus.loaded,
            ticket: ticket,
            trackingViewData: trackingViewData,
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.text('Aktivitas Terbaru'), findsOneWidget);
        expect(find.text('Lihat perjalanan lengkap'), findsOneWidget);
        expect(find.text('Tiket dibuat'), findsWidgets);
      },
    );

    testWidgets(
      'membatasi preview aktivitas maksimal tiga item',
      (tester) async {
        final activities = List.generate(
          5,
          (_) => trackingViewData.activityEvents.first,
          growable: false,
        );

        final viewDataWithManyActivities = TicketTrackingViewData(
          lifecycleMilestones: trackingViewData.lifecycleMilestones,
          activityEvents: activities,
          currentStatus: trackingViewData.currentStatus,
          isClosed: trackingViewData.isClosed,
          isReopened: trackingViewData.isReopened,
        );

        when(() => mockDetailBloc.state).thenReturn(
          TicketDetailState(
            status: TicketDetailStatus.loaded,
            ticket: ticket,
            trackingViewData: viewDataWithManyActivities,
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.text('Aktivitas Terbaru'), findsOneWidget);

        // Lima aktivitas diberikan, tetapi preview hanya merender tiga.
        expect(
          find.text('Tiket dibuat'),
          findsNWidgets(3),
        );
      },
    );

    testWidgets(
      'tiket closed menampilkan milestone Ditutup',
      (tester) async {
        final closedTicket = TicketEntity(
          id: 'ticket-closed',
          title: 'Printer Error',
          description: 'Printer cannot print',
          status: TicketStatus.closed,
          category: 'Hardware',
          createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
          updatedAt: DateTime.parse('2026-06-30T12:00:00Z'),
          userId: 'user-1',
          userName: 'Test User',
        );

        final closedTrackingViewData =
            const TicketTrackingTimelineBuilder().build(
          ticket: closedTicket,
          history: const [],
        );

        when(() => mockDetailBloc.state).thenReturn(
          TicketDetailState(
            status: TicketDetailStatus.loaded,
            ticket: closedTicket,
            trackingViewData: closedTrackingViewData,
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.text('PERJALANAN TIKET'), findsOneWidget);

        final closedMilestoneFinder = find.descendant(
          of: find.byType(TicketLifecycleProgress),
          matching: find.text('Ditutup'),
        );

        expect(closedMilestoneFinder, findsOneWidget);
      },
    );

    testWidgets(
      'menavigasi ke tracking lengkap ketika tombol ditekan',
      (tester) async {
        when(() => mockDetailBloc.state).thenReturn(
          TicketDetailState(
            status: TicketDetailStatus.loaded,
            ticket: ticket,
            trackingViewData: trackingViewData,
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        final navigationButton = find.text('Lihat perjalanan lengkap');

        expect(navigationButton, findsOneWidget);

        // Tombol berada di bawah viewport default widget test.
        // Scroll halaman sampai tombol benar-benar terlihat dan dapat ditekan.
        await tester.scrollUntilVisible(
          navigationButton,
          300,
          scrollable: find.byType(Scrollable).first,
        );

        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(navigationButton);

        // Hindari pumpAndSettle karena halaman detail dapat memiliki animasi
        // atau stream aktif yang membuat scheduler tidak pernah benar-benar idle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byKey(trackingDestinationKey), findsOneWidget);
        expect(find.text('Halaman Tracking Lengkap'), findsOneWidget);
      },
    );
  });
}
