import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/value_objects/ticket_query.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_event.dart';
import 'package:uts/features/ticket/presentation/bloc/create/ticket_create_state.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_state.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart';
import 'package:uts/features/ticket/presentation/pages/create_ticket_page.dart';

class _MockTicketCreateBloc
    extends MockBloc<TicketCreateEvent, TicketCreateState>
    implements TicketCreateBloc {}

class _MockTicketListBloc extends MockBloc<TicketListEvent, TicketListState>
    implements TicketListBloc {}

class _MockTicketStatsBloc extends MockBloc<TicketStatsEvent, TicketStatsState>
    implements TicketStatsBloc {}

void main() {
  const dashboardKey = Key('dashboard-origin');
  const standaloneListKey = Key('standalone-ticket-list-origin');
  const detailKey = Key('ticket-detail-destination');

  late _MockTicketCreateBloc createBloc;
  late _MockTicketListBloc listBloc;
  late _MockTicketStatsBloc statsBloc;

  final createdTicket = TicketEntity(
    id: 'created-ticket-123',
    title: 'Printer Error',
    description: 'Printer lantai 2 tidak dapat mencetak.',
    status: TicketStatus.open,
    category: 'hardware',
    createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
    userId: 'user-1',
  );

  setUp(() {
    createBloc = _MockTicketCreateBloc();
    listBloc = _MockTicketListBloc();
    statsBloc = _MockTicketStatsBloc();

    final createState = TicketCreateState(
      status: TicketCreateStatus.success,
      ticket: createdTicket,
      message: 'Laporan berhasil dibuat',
    );

    whenListen(
      createBloc,
      const Stream<TicketCreateState>.empty(),
      initialState: createState,
    );
    when(() => createBloc.state).thenReturn(createState);

    whenListen(
      listBloc,
      const Stream<TicketListState>.empty(),
      initialState: TicketListState.initial().copyWith(
        query: TicketQuery(search: 'printer'),
      ),
    );
    when(() => listBloc.state).thenReturn(
      TicketListState.initial().copyWith(
        query: TicketQuery(search: 'printer'),
      ),
    );

    whenListen(
      statsBloc,
      const Stream<TicketStatsState>.empty(),
      initialState: const TicketStatsState(),
    );
    when(() => statsBloc.state).thenReturn(const TicketStatsState());
  });

  Widget buildHarness({required String initialLocation}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const _OriginPage(
            key: dashboardKey,
            label: 'Dashboard tab tiket',
          ),
        ),
        GoRoute(
          path: AppRoutes.tickets,
          builder: (context, state) => const _OriginPage(
            key: standaloneListKey,
            label: 'Standalone ticket list',
          ),
        ),
        GoRoute(
          path: AppRoutes.createTicket,
          name: 'create-ticket',
          builder: (context, state) => const CreateTicketPage(),
        ),
        GoRoute(
          path: AppRoutes.ticketDetail,
          name: 'ticket-detail',
          builder: (context, state) => _DetailHarness(
            key: detailKey,
            ticketId: state.pathParameters['id']!,
          ),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<TicketCreateBloc>.value(value: createBloc),
        BlocProvider<TicketListBloc>.value(value: listBloc),
        BlocProvider<TicketStatsBloc>.value(value: statsBloc),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets(
    'Dashboard ticket tab -> create -> detail -> back returns to Dashboard tab',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(initialLocation: AppRoutes.dashboard),
      );

      expect(find.byKey(dashboardKey), findsOneWidget);
      expect(find.text('Dashboard tab tiket'), findsOneWidget);

      await tester.tap(find.text('Buat Tiket'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lihat Tiket'));
      await tester.pumpAndSettle();

      expect(find.byKey(detailKey), findsOneWidget);
      expect(find.text('Detail created-ticket-123'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(dashboardKey), findsOneWidget);
      expect(find.text('Dashboard tab tiket'), findsOneWidget);
      expect(find.byKey(standaloneListKey), findsNothing);
    },
  );

  testWidgets(
    '/tickets standalone -> create -> detail -> app bar back returns to /tickets',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(initialLocation: AppRoutes.tickets),
      );

      expect(find.byKey(standaloneListKey), findsOneWidget);

      await tester.tap(find.text('Buat Tiket'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lihat Tiket'));
      await tester.pumpAndSettle();

      expect(find.byKey(detailKey), findsOneWidget);
      expect(find.text('Detail created-ticket-123'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byKey(standaloneListKey), findsOneWidget);
      expect(find.text('Standalone ticket list'), findsOneWidget);
      expect(find.byKey(dashboardKey), findsNothing);
    },
  );
}

class _OriginPage extends StatelessWidget {
  final String label;

  const _OriginPage({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.push(AppRoutes.createTicket),
          child: const Text('Buat Tiket'),
        ),
      ),
      bottomNavigationBar: label.startsWith('Dashboard')
          ? const SizedBox(
              height: 56,
              child: Center(child: Text('Bottom navigation aktif')),
            )
          : null,
    );
  }
}

class _DetailHarness extends StatelessWidget {
  final String ticketId;

  const _DetailHarness({
    super.key,
    required this.ticketId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Detail $ticketId')),
    );
  }
}
