import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/presentation/widgets/ticket_detail_skeleton.dart';
import 'package:uts/shared/theme/app_theme.dart';

void main() {
  group('TicketDetailSkeleton', () {
    testWidgets('does not overflow on a short viewport with keyboard inset',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(411, 640),
              viewInsets: EdgeInsets.only(bottom: 280),
            ),
            child: const Scaffold(
              body: TicketDetailSkeleton(isDark: false),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('ticket-detail-skeleton-scroll-view')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('remains scrollable on a compact dark viewport',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MediaQuery(
            data: MediaQueryData(size: Size(320, 480)),
            child: Scaffold(
              body: TicketDetailSkeleton(isDark: true),
            ),
          ),
        ),
      );

      final scrollable = tester.widget<SingleChildScrollView>(
        find.byKey(const Key('ticket-detail-skeleton-scroll-view')),
      );

      expect(scrollable.physics, isA<ClampingScrollPhysics>());
      expect(tester.takeException(), isNull);
    });
  });
}
