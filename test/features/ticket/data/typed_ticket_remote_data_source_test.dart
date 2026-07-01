import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uts/core/services/realtime_session_service.dart';
import 'package:uts/features/ticket/data/datasources/typed_ticket_remote_data_source.dart';
import 'package:uts/features/ticket/data/models/ticket_model.dart';

void main() {
  late TypedSupabaseTicketRemoteDataSourceImpl dataSource;

  setUp(() {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );
    dataSource = TypedSupabaseTicketRemoteDataSourceImpl(
      client,
      realtimeSessionService: _FakeRealtimeSessionService(),
    );
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

  test('watchTickets reports authentication failure before opening stream',
      () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );
    final fakeSession = _FakeRealtimeSessionService(
      error: const RealtimeSessionException(
        type: RealtimeSessionFailureType.authentication,
        message: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
      ),
    );
    final source = TypedSupabaseTicketRemoteDataSourceImpl(
      client,
      realtimeSessionService: fakeSession,
    );

    await expectLater(
      source.watchTickets(userId: 'user-1'),
      emitsError(isA<RealtimeSessionException>()),
    );
    expect(fakeSession.ensureCalls, 1);
  });
}

class _FakeRealtimeSessionService implements RealtimeSessionService {
  final RealtimeSessionException? error;
  int ensureCalls = 0;
  int stopCalls = 0;

  _FakeRealtimeSessionService({this.error});

  @override
  int get generation => stopCalls;

  @override
  Future<void> ensureAuthenticated({required String channelName}) async {
    ensureCalls++;
    if (error != null) {
      throw error!;
    }
  }

  @override
  Future<void> stopAll({required String reason}) async {
    stopCalls++;
  }
}
