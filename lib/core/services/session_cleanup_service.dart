import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts/core/services/fcm_service.dart';
import 'package:uts/core/services/local_notification_service.dart';

/// Membersihkan data yang hanya boleh hidup selama satu sesi akun.
class SessionCleanupService {
  static const String _ticketListCacheKey = 'cached_tickets';
  static const String _ticketDetailCachePrefix = 'cached_ticket_detail_';

  final SharedPreferences preferences;
  final FCMService fcmService;
  final LocalNotificationService localNotificationService;

  const SessionCleanupService({
    required this.preferences,
    required this.fcmService,
    required this.localNotificationService,
  });

  /// Dipanggil sebelum Supabase sign-out agar RPC pencabutan token masih
  /// memiliki sesi autentikasi yang valid.
  Future<void> clearBeforeLogout() async {
    await fcmService.unregisterCurrentDeviceToken();
    await localNotificationService.cancelAll();
    await _clearTicketCache();
  }

  Future<void> _clearTicketCache() async {
    final keys = preferences.getKeys().where(
          (key) =>
              key == _ticketListCacheKey ||
              key.startsWith(_ticketDetailCachePrefix),
        );
    for (final key in keys.toList(growable: false)) {
      await preferences.remove(key);
    }
  }
}
