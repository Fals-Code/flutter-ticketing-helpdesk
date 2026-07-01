import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/data/models/ticket_history_model.dart';
import 'package:uts/features/ticket/domain/entities/ticket_tracking_item.dart';

void main() {
  group('TicketHistoryModel', () {
    test('history model mapping reads event type and description', () {
      final model = TicketHistoryModel.fromJson({
        'id': 'hist-1',
        'ticket_id': 'ticket-1',
        'event_type': 'comment',
        'changed_by': 'user-1',
        'created_at': '2026-06-01T10:00:00.000Z',
        'reason': 'Komentar baru ditambahkan',
      });

      expect(model.activityType, 'comment');
      expect(model.description, 'Komentar baru ditambahkan');
    });

    test('history without oldStatus and newStatus stays valid', () {
      final model = TicketHistoryModel.fromJson({
        'id': 'hist-2',
        'ticket_id': 'ticket-1',
        'changed_by': 'user-1',
        'created_at': '2026-06-01T10:00:00.000Z',
      });

      expect(model.oldStatus, isNull);
      expect(model.newStatus, isNull);
    });

    test('tracking item mapping converts history into timeline item', () {
      final history = TicketHistoryModel.fromJson({
        'id': 'hist-3',
        'ticket_id': 'ticket-1',
        'event_type': 'ticket_created',
        'changed_by': 'user-1',
        'changed_by_name': 'Reporter',
        'created_at': '2026-06-01T10:00:00.000Z',
      }).toEntity();

      final tracking = TicketTrackingItem.fromHistory(history);

      expect(tracking.ticketId, 'ticket-1');
      expect(tracking.title, 'Tiket Dibuat');
      expect(tracking.actorName, 'Reporter');
    });

    test('history mapper does not reorder list data', () {
      final rows = [
        {
          'id': 'hist-1',
          'ticket_id': 'ticket-1',
          'changed_by': 'user-1',
          'created_at': '2026-06-01T10:00:00.000Z',
        },
        {
          'id': 'hist-2',
          'ticket_id': 'ticket-1',
          'changed_by': 'user-1',
          'created_at': '2026-06-01T11:00:00.000Z',
        },
      ];

      final ids =
          rows.map(TicketHistoryModel.fromJson).map((item) => item.id).toList();

      expect(ids, ['hist-1', 'hist-2']);
    });
  });
}
