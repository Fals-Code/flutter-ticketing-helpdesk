import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/services/fcm_service.dart';
import 'package:uts/core/services/local_notification_service.dart';
import 'package:uts/core/services/session_cleanup_service.dart';
import 'package:uts/features/ticket/data/datasources/ticket_local_data_source.dart';
import 'package:uts/features/ticket/data/models/ticket_model.dart';

void main() {
  group('SessionCleanupService', () {
    test('clears ticket cache even when local notification cleanup fails',
        () async {
      final fcmService = _FakeFCMService();
      final localNotifications = _FakeLocalNotificationService(
        throwOnCancel: true,
      );
      final ticketLocalDataSource = _FakeTicketLocalDataSource();
      final service = SessionCleanupService(
        fcmService: fcmService,
        localNotificationService: localNotifications,
        ticketLocalDataSource: ticketLocalDataSource,
      );

      await service.clearBeforeLogout();

      expect(fcmService.unregisterCallCount, 1);
      expect(localNotifications.cancelAllCallCount, 1);
      expect(ticketLocalDataSource.clearCacheCallCount, 1);
    });

    test('propagates cache cleanup failure after cleanup steps run', () async {
      final fcmService = _FakeFCMService();
      final localNotifications = _FakeLocalNotificationService();
      final ticketLocalDataSource = _FakeTicketLocalDataSource(
        clearCacheError: Exception('cache failure'),
      );
      final service = SessionCleanupService(
        fcmService: fcmService,
        localNotificationService: localNotifications,
        ticketLocalDataSource: ticketLocalDataSource,
      );

      await expectLater(
        service.clearBeforeLogout(),
        throwsException,
      );
      expect(fcmService.unregisterCallCount, 1);
      expect(localNotifications.cancelAllCallCount, 1);
      expect(ticketLocalDataSource.clearCacheCallCount, 1);
    });
  });
}

class _FakeFCMService implements FCMService {
  int unregisterCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncTokenToSupabase(String userId, [String? token]) async {}

  @override
  Future<void> unregisterCurrentDeviceToken() async {
    unregisterCallCount++;
  }
}

class _FakeLocalNotificationService implements LocalNotificationService {
  final bool throwOnCancel;
  int cancelAllCallCount = 0;

  _FakeLocalNotificationService({this.throwOnCancel = false});

  @override
  Future<void> cancelAll() async {
    cancelAllCallCount++;
    if (throwOnCancel) {
      throw Exception('notification failure');
    }
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}
}

class _FakeTicketLocalDataSource implements TicketLocalDataSource {
  final Object? clearCacheError;
  int clearCacheCallCount = 0;

  _FakeTicketLocalDataSource({this.clearCacheError});

  @override
  Future<void> cacheTicketDetail(TicketModel ticket) async {}

  @override
  Future<void> cacheTickets(List<TicketModel> tickets) async {}

  @override
  Future<void> clearCache() async {
    clearCacheCallCount++;
    if (clearCacheError != null) {
      throw clearCacheError!;
    }
  }

  @override
  Future<TicketModel?> getCachedTicketDetail(String ticketId) async => null;

  @override
  Future<List<TicketModel>> getCachedTickets() async => const [];

  @override
  Future<void> removeCachedTicketDetail(String ticketId) async {}
}
