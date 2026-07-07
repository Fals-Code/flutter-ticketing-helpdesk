import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';
import 'package:uts/shared/widgets/ticket_timeline_widget.dart';

void main() {
  testWidgets(
    'menggabungkan assignment dan status change menjadi satu aktivitas',
    (WidgetTester tester) async {
      final DateTime createdAt = DateTime.utc(2026, 7, 7, 4, 2);
      final List<TicketHistoryEntity> activities = <TicketHistoryEntity>[
        TicketHistoryEntity(
          id: 'assigned-event',
          ticketId: 'ticket-1',
          eventType: 'assigned',
          oldStatus: 'open',
          newStatus: 'in_progress',
          changedBy: 'admin-1',
          changedByName: 'Admin',
          createdAt: createdAt.add(const Duration(milliseconds: 200)),
        ),
        TicketHistoryEntity(
          id: 'status-event',
          ticketId: 'ticket-1',
          eventType: 'status_changed',
          oldStatus: 'open',
          newStatus: 'in_progress',
          changedBy: 'admin-1',
          changedByName: 'Admin',
          createdAt: createdAt,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketTimelineWidget(
              activities: activities,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Ditugaskan & Mulai Dikerjakan'), findsOneWidget);
      expect(find.text('Mulai Dikerjakan'), findsNothing);
      expect(
        find.text(
          'Tiket ditugaskan kepada teknisi dan status berubah dari '
          'Terbuka menjadi Diproses.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tetap menampilkan status change tunggal sebagai aktivitas biasa',
    (WidgetTester tester) async {
      final List<TicketHistoryEntity> activities = <TicketHistoryEntity>[
        TicketHistoryEntity(
          id: 'status-event',
          ticketId: 'ticket-1',
          eventType: 'status_changed',
          oldStatus: 'open',
          newStatus: 'in_progress',
          changedBy: 'helpdesk-1',
          changedByName: 'Helpdesk',
          createdAt: DateTime.utc(2026, 7, 7, 4, 2),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketTimelineWidget(
              activities: activities,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Mulai Dikerjakan'), findsOneWidget);
      expect(find.text('Ditugaskan & Mulai Dikerjakan'), findsNothing);
    },
  );
}
