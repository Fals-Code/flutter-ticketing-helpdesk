import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/presentation/widgets/ticket_list_filter_header.dart';
import 'package:uts/shared/theme/app_theme.dart';

void main() {
  group('TicketListFilterHeader', () {
    testWidgets('renders compact light header without overflow', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          theme: AppTheme.lightTheme,
          child: TicketListFilterHeader(
            isDark: false,
            searchField: const SizedBox(
              key: Key('search-field'),
              height: 44,
            ),
            filterButton: const SizedBox(
              key: Key('filter-button'),
              width: 44,
              height: 44,
            ),
            statusChips: const [
              SizedBox(key: Key('status-all'), width: 72, height: 28),
              SizedBox(key: Key('status-open'), width: 84, height: 28),
            ],
          ),
        ),
      );

      expect(find.byKey(const Key('search-field')), findsOneWidget);
      expect(find.byKey(const Key('filter-button')), findsOneWidget);
      expect(find.byKey(const Key('status-all')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders expanded dark header at larger text scale',
        (tester) async {
      await tester.pumpWidget(
        _TestApp(
          theme: AppTheme.darkTheme,
          textScale: 1.3,
          height: 180,
          child: TicketListFilterHeader(
            isDark: true,
            searchField: const SizedBox(
              key: Key('search-field'),
              height: 44,
            ),
            filterButton: const SizedBox(
              key: Key('filter-button'),
              width: 44,
              height: 44,
            ),
            assigneeFilterButton: const SizedBox(
              key: Key('assignee-filter'),
              width: 44,
              height: 44,
            ),
            activeAssigneeChip: const SizedBox(
              key: Key('active-assignee'),
              height: 32,
            ),
            statusChips: const [
              SizedBox(key: Key('status-all'), width: 72, height: 28),
              SizedBox(key: Key('status-progress'), width: 96, height: 28),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('assignee-filter')), findsOneWidget);
      expect(find.byKey(const Key('active-assignee')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expanded preferred height is larger than compact height',
        (tester) async {
      double? compactHeight;
      double? expandedHeight;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Builder(
              builder: (context) {
                compactHeight = TicketListFilterHeader.preferredHeight(
                  context,
                  expanded: false,
                );
                expandedHeight = TicketListFilterHeader.preferredHeight(
                  context,
                  expanded: true,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(compactHeight, isNotNull);
      expect(expandedHeight, isNotNull);
      expect(expandedHeight!, greaterThan(compactHeight!));
      expect(tester.takeException(), isNull);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.theme,
    required this.child,
    this.textScale = 1,
    this.height = 140,
  });

  final ThemeData theme;
  final Widget child;
  final double textScale;
  final double height;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 640),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 320,
              height: height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
