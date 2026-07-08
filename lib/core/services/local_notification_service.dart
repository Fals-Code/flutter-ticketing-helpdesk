import 'dart:io';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:uts/core/di/injection_container.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/features/notification/domain/usecases/notification_usecases.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? _pendingLaunchPayload;

  static const String channelId = 'ticketq_ticket_updates';
  static const String channelName = 'Pembaruan Tiket';
  static const String channelDescription =
      'Notifikasi penting untuk update, komentar, dan assignment tiket.';

  static const AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDescription,
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticketq',
    playSound: true,
    enableVibration: true,
    color: Color(0xFF2196F3),
    channelShowBadge: true,
    icon: '@mipmap/ic_launcher',
  );

  static const DarwinNotificationDetails _darwinNotificationDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const NotificationDetails _platformNotificationDetails =
      NotificationDetails(
    android: _androidNotificationDetails,
    iOS: _darwinNotificationDetails,
  );

  static const AndroidInitializationSettings _androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  static const DarwinInitializationSettings _darwinInitializationSettings =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  static const InitializationSettings _initializationSettings =
      InitializationSettings(
    android: _androidInitializationSettings,
    iOS: _darwinInitializationSettings,
  );

  Future<void> initialize() async {
    tz.initializeTimeZones();

    await _notificationsPlugin.initialize(
      settings: _initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await _handlePayloadTap(response.payload);
      },
    );

    final launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _pendingLaunchPayload = launchDetails?.notificationResponse?.payload;
    }

    await _ensureAndroidChannel(_notificationsPlugin);

    if (!kIsWeb && Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlatform =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlatform?.requestNotificationsPermission();
    }
  }

  Future<void> consumePendingLaunchPayload() async {
    final payload = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    await _handlePayloadTap(payload);
  }

  static Future<void> showBackgroundRemoteMessage(RemoteMessage message) async {
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();

    await plugin.initialize(settings: _initializationSettings);
    await _ensureAndroidChannel(plugin);

    final String title = _firstNonEmpty([
      message.notification?.title,
      message.data['title']?.toString(),
      message.data['notification_title']?.toString(),
      'Pembaruan Tiket',
    ]);
    final String body = _firstNonEmpty([
      message.notification?.body,
      message.data['body']?.toString(),
      message.data['message']?.toString(),
      'Ketuk untuk melihat detail tiket.',
    ]);
    final String? payload = payloadFromData(message.data);
    final int notificationId = _stableNotificationId(message, payload);

    await plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: _platformNotificationDetails,
      payload: payload,
    );
  }

  static String? payloadFromData(Map<String, dynamic> data) {
    final String notificationId = _firstNonEmpty([
      data['notificationId']?.toString(),
      data['notification_id']?.toString(),
      data['id']?.toString(),
    ]);
    final String ticketId = _firstNonEmpty([
      data['ticketId']?.toString(),
      data['ticket_id']?.toString(),
    ]);

    if (notificationId.isEmpty && ticketId.isEmpty) {
      return null;
    }
    return '$notificationId|$ticketId';
  }

  static String? ticketIdFromData(Map<String, dynamic> data) {
    final String value = _firstNonEmpty([
      data['ticketId']?.toString(),
      data['ticket_id']?.toString(),
    ]);
    return value.isEmpty ? null : value;
  }

  static String? notificationIdFromData(Map<String, dynamic> data) {
    final String value = _firstNonEmpty([
      data['notificationId']?.toString(),
      data['notification_id']?.toString(),
      data['id']?.toString(),
    ]);
    return value.isEmpty ? null : value;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _platformNotificationDetails,
      payload: payload,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> _ensureAndroidChannel(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    final AndroidFlutterLocalNotificationsPlugin? androidPlatform =
        plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlatform?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  static Future<void> _handlePayloadTap(String? payload) async {
    if (payload == null || payload.isEmpty) {
      return;
    }

    debugPrint('Notification tapped with payload: $payload');
    final parts = payload.split('|');
    if (parts.length > 1) {
      final notificationId = parts[0];
      final ticketId = parts[1];
      if (notificationId.isNotEmpty) {
        final result = await sl<MarkNotificationAsRead>().call(notificationId);
        result.fold(
          (failure) => debugPrint(
            'Failed to mark notification as read: ${failure.message}',
          ),
          (_) => debugPrint(
            'Successfully marked notification $notificationId as read.',
          ),
        );
      }
      if (ticketId.isNotEmpty) {
        appRouter.push(
          AppRoutes.ticketDetail.replaceAll(':id', ticketId),
        );
      }
    } else {
      appRouter.push(
        AppRoutes.ticketDetail.replaceAll(':id', payload),
      );
    }
  }

  static int _stableNotificationId(RemoteMessage message, String? payload) {
    final source = _firstNonEmpty([
      message.messageId,
      message.data['notificationId']?.toString(),
      message.data['notification_id']?.toString(),
      payload,
      DateTime.now().microsecondsSinceEpoch.toString(),
    ]);
    return source.hashCode;
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }
}
