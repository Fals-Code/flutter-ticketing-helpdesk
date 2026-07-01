import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/services/ticket_collection_utils.dart';
import 'package:uts/features/ticket/domain/value_objects/ticket_query.dart';

void main() {
  group('ticket collection utils', () {
    test('mergeTicketPage deduplicates by id', () {
      final merged = mergeTicketPage(
        existing: [
          _ticket(id: '1', updatedAt: DateTime.parse('2026-06-30T10:00:00Z')),
        ],
        incoming: [
          _ticket(id: '1', updatedAt: DateTime.parse('2026-06-30T11:00:00Z')),
          _ticket(id: '2', updatedAt: DateTime.parse('2026-06-30T09:00:00Z')),
        ],
      );

      expect(merged.map((ticket) => ticket.id).toList(), ['1', '2']);
      expect(merged.first.updatedAt, DateTime.parse('2026-06-30T11:00:00Z'));
    });

    test('mergeTicketPage keeps newer existing item when incoming older', () {
      final merged = mergeTicketPage(
        existing: [
          _ticket(id: '1', updatedAt: DateTime.parse('2026-06-30T11:00:00Z')),
        ],
        incoming: [
          _ticket(id: '1', updatedAt: DateTime.parse('2026-06-30T10:00:00Z')),
        ],
      );

      expect(merged.single.updatedAt, DateTime.parse('2026-06-30T11:00:00Z'));
    });

    test('compareTicketsDeterministically uses id as secondary key', () {
      final sorted = sortTicketsDeterministically([
        _ticket(
          id: '1',
          updatedAt: DateTime.parse('2026-06-30T10:00:00Z'),
        ),
        _ticket(
          id: '2',
          updatedAt: DateTime.parse('2026-06-30T10:00:00Z'),
        ),
      ]);

      expect(sorted.map((ticket) => ticket.id).toList(), ['2', '1']);
    });

    test('matchesTicketQuery applies search and status filters', () {
      final query = TicketQuery(
        search: 'printer',
        status: TicketStatus.open,
      );

      expect(
        matchesTicketQuery(
          _ticket(
            id: '1',
            title: 'Printer bermasalah',
            status: TicketStatus.open,
          ),
          query,
        ),
        isTrue,
      );
      expect(
        matchesTicketQuery(
          _ticket(
            id: '2',
            title: 'Jaringan putus',
            description: 'Akses internet kantor bermasalah.',
            status: TicketStatus.open,
          ),
          query,
        ),
        isFalse,
      );
    });

    test('applyRealtimeSnapshot inserts new top item without duplicates', () {
      final result = applyRealtimeSnapshot(
        currentItems: [
          _ticket(
            id: '1',
            updatedAt: DateTime.parse('2026-06-30T10:00:00Z'),
          ),
          _ticket(
            id: '2',
            updatedAt: DateTime.parse('2026-06-30T09:00:00Z'),
          ),
        ],
        snapshotItems: [
          _ticket(
            id: '3',
            updatedAt: DateTime.parse('2026-06-30T12:00:00Z'),
          ),
          _ticket(
            id: '1',
            updatedAt: DateTime.parse('2026-06-30T10:00:00Z'),
          ),
          _ticket(
            id: '2',
            updatedAt: DateTime.parse('2026-06-30T09:00:00Z'),
          ),
        ],
        query: TicketQuery(limit: 2),
        hasMore: true,
      );

      expect(result.map((ticket) => ticket.id).toList(), ['3', '1']);
    });

    test('applyRealtimeSnapshot removes item no longer in snapshot', () {
      final result = applyRealtimeSnapshot(
        currentItems: [
          _ticket(id: '1'),
          _ticket(id: '2'),
        ],
        snapshotItems: [
          _ticket(id: '2'),
        ],
        query: TicketQuery(limit: 2),
        hasMore: false,
      );

      expect(result.map((ticket) => ticket.id).toList(), ['2']);
    });

    test('removeRealtimeTicket removes matching id', () {
      final result = removeRealtimeTicket([
        _ticket(id: '1'),
        _ticket(id: '2'),
      ], '1');

      expect(result.map((ticket) => ticket.id).toList(), ['2']);
    });
  });
}

TicketEntity _ticket({
  required String id,
  String title = 'Printer error',
  String description = 'Printer lantai 2 tidak dapat mencetak.',
  TicketStatus status = TicketStatus.open,
  DateTime? updatedAt,
}) {
  return TicketEntity(
    id: id,
    title: title,
    description: description,
    status: status,
    category: 'hardware',
    createdAt: DateTime.parse('2026-06-30T08:00:00Z'),
    updatedAt: updatedAt,
    userId: 'user-1',
  );
}
