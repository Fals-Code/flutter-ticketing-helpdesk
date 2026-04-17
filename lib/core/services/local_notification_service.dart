import 'dart:io';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/core/di/injection_container.dart';
import 'package:uts/features/notification/domain/usecases/notification_usecases.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDescription = 'This channel is used for important helpdesk notifications.';

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap logic here
        final String? payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('Notification tapped with payload: $payload');
          // Payload format: "notificationId|ticketId"
          final parts = payload.split('|');
          if (parts.length > 1) {
            final notificationId = parts[0];
            final ticketId = parts[1];
            
            // Mark as read in the database
            if (notificationId.isNotEmpty) {
              final result = await sl<MarkNotificationAsRead>().call(notificationId);
              result.fold(
                (failure) => debugPrint('Failed to mark notification as read: ${failure.message}'),
                (_) => debugPrint('Successfully marked notification $notificationId as read via background tap.'),
              );
            }

            if (ticketId.isNotEmpty) {
              appRouter.push(AppRoutes.ticketDetail.replaceAll(':id', ticketId));
            }
          } else {
            // Fallback for old simple payloads (just ticketId)
            appRouter.push(AppRoutes.ticketDetail.replaceAll(':id', payload));
          }
        }
      },
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlatform =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlatform?.requestNotificationsPermission();
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      color: Color(0xFF2196F3),
      channelShowBadge: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }
}
