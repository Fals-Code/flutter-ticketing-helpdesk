import 'package:uts/core/services/fcm_service.dart';
import 'package:uts/core/services/local_notification_service.dart';
import 'package:uts/core/services/realtime_session_service.dart';
import 'package:uts/features/ticket/data/datasources/ticket_local_data_source.dart';

/// Membersihkan data yang hanya boleh hidup selama satu sesi akun.
class SessionCleanupService {
  final FCMService fcmService;
  final LocalNotificationService localNotificationService;
  final TicketLocalDataSource ticketLocalDataSource;
  final RealtimeSessionService? realtimeSessionService;

  const SessionCleanupService({
    required this.fcmService,
    required this.localNotificationService,
    required this.ticketLocalDataSource,
    this.realtimeSessionService,
  });

  /// Cleanup lokal tetap dijalankan walaupun pencabutan token remote gagal.
  Future<void> clearBeforeLogout() async {
    await realtimeSessionService?.stopAll(reason: 'logout');

    await fcmService.unregisterCurrentDeviceToken();

    try {
      await localNotificationService.cancelAll();
    } catch (_) {
      // Local cache must still be cleared.
    }

    await ticketLocalDataSource.clearCache();
  }
}
