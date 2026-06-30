import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/ticket/data/datasources/ticket_local_data_source.dart';
import 'package:uts/features/ticket/data/models/ticket_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsTicketLocalDataSource', () {
    late SharedPreferences preferences;
    late _MutableSessionProvider sessionProvider;
    late SharedPrefsTicketLocalDataSource dataSource;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      sessionProvider = _MutableSessionProvider('user-a');
      dataSource = SharedPrefsTicketLocalDataSource(
        preferences,
        sessionProvider: sessionProvider,
      );
    });

    test('uses authenticated user id for list cache keys', () async {
      await dataSource.cacheTickets([_ticket('ticket-1')]);

      expect(preferences.containsKey('ticket_list::user-a'), isTrue);
      expect(preferences.containsKey('cached_tickets'), isFalse);
    });

    test('user B does not read list cache of user A', () async {
      await dataSource.cacheTickets([_ticket('ticket-1')]);

      sessionProvider.activeUserId = 'user-b';

      expect(
        dataSource.getCachedTickets,
        throwsA(isA<CacheException>()),
      );
    });

    test('user B does not read ticket detail cache of user A', () async {
      await dataSource.cacheTicketDetail(_ticket('ticket-1'));

      sessionProvider.activeUserId = 'user-b';

      expect(await dataSource.getCachedTicketDetail('ticket-1'), isNull);
    });

    test('clears legacy global ticket cache without touching other preferences',
        () async {
      await preferences.setString('cached_tickets', 'legacy-list');
      await preferences.setString('cached_ticket_detail_ticket-1', 'legacy');
      await preferences.setString('app_theme', 'light');

      await dataSource.clearCache();

      expect(preferences.containsKey('cached_tickets'), isFalse);
      expect(
        preferences.containsKey('cached_ticket_detail_ticket-1'),
        isFalse,
      );
      expect(preferences.getString('app_theme'), 'light');
    });

    test('cache read without active session is rejected', () async {
      sessionProvider.activeUserId = null;

      expect(
        dataSource.getCachedTickets,
        throwsA(
          isA<CacheException>().having(
            (error) => error.message,
            'message',
            'Active ticket cache session not found.',
          ),
        ),
      );
    });

    test('clearCache only clears active user namespace', () async {
      await dataSource.cacheTickets([_ticket('ticket-1')]);
      await dataSource.cacheTicketDetail(_ticket('ticket-1'));

      sessionProvider.activeUserId = 'user-b';
      await dataSource.cacheTickets([_ticket('ticket-2', userId: 'user-b')]);
      await dataSource.cacheTicketDetail(_ticket('ticket-2', userId: 'user-b'));

      sessionProvider.activeUserId = 'user-a';
      await dataSource.clearCache();

      expect(preferences.containsKey('ticket_list::user-a'), isFalse);
      expect(
        preferences.containsKey('ticket_detail::user-a::ticket-1'),
        isFalse,
      );
      expect(preferences.containsKey('ticket_list::user-b'), isTrue);
      expect(
          preferences.containsKey('ticket_detail::user-b::ticket-2'), isTrue);
    });
  });
}

class _MutableSessionProvider implements TicketCacheSessionProvider {
  String? _activeUserId;

  _MutableSessionProvider(this._activeUserId);

  set activeUserId(String? value) => _activeUserId = value;

  @override
  String? get activeUserId => _activeUserId;
}

TicketModel _ticket(String id, {String userId = 'user-a'}) {
  return TicketModel(
    id: id,
    title: 'Printer Error',
    description: 'Printer lantai 2 tidak dapat mencetak.',
    status: TicketStatus.open,
    category: 'hardware',
    createdAt: DateTime.parse('2026-06-30T10:00:00Z'),
    updatedAt: DateTime.parse('2026-06-30T10:00:00Z'),
    userId: userId,
  );
}
