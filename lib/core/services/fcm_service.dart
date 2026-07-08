import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:uts/core/di/injection_container.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/features/notification/domain/usecases/notification_usecases.dart';
import 'local_notification_service.dart';

class FCMService {
  static const String _deviceIdKey = 'ticketq_device_id';

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final LocalNotificationService _localNotifications;
  final SharedPreferences _preferences;
  final SupabaseClient _supabase = sl<SupabaseClient>();
  RemoteMessage? _pendingInitialMessage;

  FCMService(this._localNotifications, this._preferences);

  Future<void> initialize() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification permission granted');
    }

    await syncCurrentUserToken();

    _fcm.onTokenRefresh.listen((newToken) async {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        await syncTokenToSupabase(currentUserId, newToken);
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      final payload = LocalNotificationService.payloadFromData(message.data);
      _localNotifications.showNotification(
        id: message.hashCode,
        title: message.notification?.title ??
            message.data['title']?.toString() ??
            'Pembaruan Tiket',
        body: message.notification?.body ??
            message.data['body']?.toString() ??
            message.data['message']?.toString() ??
            'Ketuk untuk melihat detail',
        payload: payload,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageTap(message);
    });

    _pendingInitialMessage = await _fcm.getInitialMessage();
  }

  Future<void> syncCurrentUserToken() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    await syncTokenToSupabase(userId);
  }

  Future<void> consumePendingInitialMessage() async {
    final message = _pendingInitialMessage;
    _pendingInitialMessage = null;
    if (message != null) {
      await _handleMessageTap(message);
    }
  }

  Future<void> syncTokenToSupabase(String userId, [String? token]) async {
    try {
      if (_supabase.auth.currentUser?.id != userId) {
        return;
      }

      final fcmToken = token ?? await _fcm.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        return;
      }

      await _supabase.rpc(
        'register_device_token',
        params: {
          'p_token': fcmToken,
          'p_platform': _platform,
          'p_device_id': await _getOrCreateDeviceId(),
        },
      );
    } catch (error) {
      debugPrint('Unable to register FCM token: $error');
    }
  }

  /// Harus dipanggil sebelum Supabase sign-out agar RPC masih memiliki JWT.
  Future<void> unregisterCurrentDeviceToken() async {
    if (_supabase.auth.currentUser == null) {
      return;
    }
    try {
      await _supabase.rpc(
        'unregister_device_token',
        params: {'p_device_id': await _getOrCreateDeviceId()},
      );
    } catch (error) {
      debugPrint('Unable to unregister FCM token: $error');
    }
  }

  Future<void> _handleMessageTap(RemoteMessage message) async {
    final ticketId = LocalNotificationService.ticketIdFromData(message.data);
    final notificationId =
        LocalNotificationService.notificationIdFromData(message.data);

    if (notificationId != null && notificationId.isNotEmpty) {
      final result = await sl<MarkNotificationAsRead>().call(notificationId);
      result.fold(
        (failure) => debugPrint(
          'Failed to mark notification as read: ${failure.message}',
        ),
        (_) => null,
      );
    }

    if (ticketId != null && ticketId.isNotEmpty) {
      appRouter.push(AppRoutes.ticketDetail.replaceAll(':id', ticketId));
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = _preferences.getString(_deviceIdKey);
    if (existing != null && existing.length >= 3) {
      return existing;
    }

    final generated = const Uuid().v4();
    await _preferences.setString(_deviceIdKey, generated);
    return generated;
  }

  String get _platform {
    if (kIsWeb) {
      return 'web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }
}
