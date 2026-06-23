import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_q/features/ticket/data/datasources/typed_ticket_remote_data_source.dart';
import 'package:ticket_q/features/ticket/data/models/ticket_model.dart';

void main() {
  late TypedSupabaseTicketRemoteDataSourceImpl dataSource;

  setUp(() {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );
    dataSource = TypedSupabaseTicketRemoteDataSourceImpl(client);
  });

  test('watchTickets returns a strongly typed stream for one filter', () {
    final stream = dataSource.watchTickets(userId: 'user-1');

    expect(stream, isA<Stream<List<TicketModel>>>());
  });

  test('watchTickets supports user and assignee filters together', () {
    expect(
      () => dataSource.watchTickets(
        userId: 'user-1',
        assignedToId: 'staff-1',
      ),
      returnsNormally,
    );

    final stream = dataSource.watchTickets(
      userId: 'user-1',
      assignedToId: 'staff-1',
    );
    expect(stream, isA<Stream<List<TicketModel>>>());
  });
}
