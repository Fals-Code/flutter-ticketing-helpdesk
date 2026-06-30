import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uts/core/services/local_notification_service.dart';

/// Membersihkan data yang hanya boleh hidup selama satu sesi akun.
class SessionCleanupService {
  static const String _ticketListCacheKey = 'cached_tickets';
  static const String _ticketDetailCachePrefix = 'cached_ticket_detail_';

  final SharedPreferences preferences;
  final SupabaseClient supabaseClient;
  final LocalNotificationService localNotificationService;

  const SessionCleanupService({
    required this.preferences,
    required this.supabaseClient,
    required this.localNotificationService,
  });

  /// Dipanggil sebelum Supabase sign-out agar penghapusan token perangkat
  /// masih memiliki sesi autentikasi yang valid.
  Future<void> clearBeforeLogout() async {
    await _revokeDeviceTokens();
    await localNotificationService.cancelAll();
    await _clearTicketCache();
  }

  Future<void> _revokeDeviceTokens() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    await supabaseClient
        .from('device_tokens')
        .delete()
        .eq('user_id', userId);
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
