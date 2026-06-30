import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/domain/value_objects/ticket_query.dart';

void main() {
  group('TicketQuery', () {
    test('default query uses safe defaults', () {
      final query = TicketQuery();

      expect(query.page, 0);
      expect(query.limit, TicketQuery.defaultLimit);
      expect(query.offset, 0);
      expect(query.search, isNull);
    });

    test('negative page and offset are normalized', () {
      final query = TicketQuery(page: -2, offset: -10, limit: 15);

      expect(query.page, 0);
      expect(query.offset, 0);
      expect(query.limit, 15);
    });

    test('search is trimmed', () {
      final query = TicketQuery(search: '  printer error  ');

      expect(query.search, 'printer error');
    });
  });
}
