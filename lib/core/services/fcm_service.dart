import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:uts/core/router/app_router.dart';
import 'local_notification_service.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final LocalNotificationService _localNotifications;

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

    // 2. Get Token (Optional/For Debugging)
    String? token = await _fcm.getToken();
    debugPrint("FCM Token: $token");

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.notification?.title}");
      
      _localNotifications.showNotification(
        id: message.hashCode,
        title: message.notification?.title ?? 'New Ticket Update',
        body: message.notification?.body ?? 'Tap to see details',
        payload: message.data['ticketId'], // Payloads are in data
      );
    });

    // 4. Handle Tap when app is in Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Message clicked! (Background)");
      _handleMessageTap(message);
    });

    // 5. Handle Tap when app was killed (Terminated)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("Message clicked! (Terminated)");
      _handleMessageTap(initialMessage);
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    final String? ticketId = message.data['ticketId'];
    if (ticketId != null && ticketId.isNotEmpty) {
      // Navigate to detail
      appRouter.push(AppRoutes.ticketDetail.replaceAll(':id', ticketId));
    }
  }
}
