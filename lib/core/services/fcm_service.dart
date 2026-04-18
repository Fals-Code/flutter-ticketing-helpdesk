import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/core/di/injection_container.dart';
import 'package:uts/features/notification/domain/usecases/notification_usecases.dart';
import 'local_notification_service.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final LocalNotificationService _localNotifications;
  final SupabaseClient _supabase = sl<SupabaseClient>();

  FCMService(this._localNotifications);

  Future<void> initialize() async {
    // 1. Request Permission (iOS/Web)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }

    // 2. Initial Token Sync (if already logged in)
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      final token = await _fcm.getToken();
      if (token != null) {
        await syncTokenToSupabase(userId, token);
      }
    }

    // 3. Listen for Token Refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        await syncTokenToSupabase(currentUserId, newToken);
      }
    });

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.notification?.title}");
      final String ticketId = message.data['ticketId'] ?? '';
      final String notificationId = message.data['notificationId'] ?? '';
      
      _localNotifications.showNotification(
        id: message.hashCode,
        title: message.notification?.title ?? 'New Ticket Update',
        body: message.notification?.body ?? 'Tap to see details',
        payload: '$notificationId|$ticketId', // Compounded payload
      );
    });

    // 5. Handle Tap when app is in Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Message clicked! (Background)");
      _handleMessageTap(message);
    });

    // 6. Handle Tap when app was killed (Terminated)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("Message clicked! (Terminated)");
      _handleMessageTap(initialMessage);
    }
  }

  /// Syncs the FCM token to the Supabase profiles table.
  /// This ensures the server knows which device to send push notifications to.
  Future<void> syncTokenToSupabase(String userId, [String? token]) async {
    try {
      final fcmToken = token ?? await _fcm.getToken();
      if (fcmToken == null) return;

      await _supabase
          .from('profiles')
          .update({'fcm_token': fcmToken})
          .eq('id', userId);
      
      debugPrint("FCM Token synced to Supabase for user $userId");
    } catch (e) {
      debugPrint("Error syncing FCM token: $e");
    }
  }

  void _handleMessageTap(RemoteMessage message) async {
    final String? ticketId = message.data['ticketId'];
    final String? notificationId = message.data['notificationId'];

    if (notificationId != null && notificationId.isNotEmpty) {
      final result = await sl<MarkNotificationAsRead>().call(notificationId);
      result.fold(
        (failure) => debugPrint('Failed to mark notification as read from background: ${failure.message}'),
        (_) => debugPrint('Successfully marked notification $notificationId as read from FCM tap.'),
      );
    }

    if (ticketId != null && ticketId.isNotEmpty) {
      // Navigate to detail
      appRouter.push(AppRoutes.ticketDetail.replaceAll(':id', ticketId));
    }
  }
}
