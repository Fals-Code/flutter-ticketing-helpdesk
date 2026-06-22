import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uts/features/ticket/data/datasources/typed_ticket_remote_data_source.dart';
import 'package:uts/features/ticket/data/models/ticket_model.dart';

void main() {
  test('watchTickets returns a strongly typed ticket stream', () {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );
    final dataSource = TypedSupabaseTicketRemoteDataSourceImpl(client);

    expect(
      () => dataSource.watchTickets(userId: 'user-1'),
      returnsNormally,
    );

    final stream = dataSource.watchTickets(userId: 'user-1');
    expect(stream, isA<Stream<List<TicketModel>>>());
  });
}
