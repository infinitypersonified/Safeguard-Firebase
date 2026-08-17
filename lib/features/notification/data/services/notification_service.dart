import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:safeguard/core/constants/app_constants.dart';
import 'package:safeguard/core/utils/firebase_helper.dart';
import 'package:safeguard/features/notification/data/models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationModel> _notificationController =
      StreamController<NotificationModel>.broadcast();

  Stream<NotificationModel> get onNotification =>
      _notificationController.stream;

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.system,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFF6366F1),
      ledColor: Color(0xFF6366F1),
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );

    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type.name,
      isRead: false,
      createdAt: DateTime.now(),
    );
    _notificationController.add(notification);
  }

  Future<void> showSOSAlert({
    required String userName,
    String? location,
  }) async {
    await showNotification(
      title: '🚨 SOS Alert',
      body:
          '$userName has sent an emergency alert${location != null ? ' at $location' : ''}',
      payload: 'sos_alert',
      type: NotificationType.sosAlert,
    );
  }

  Future<void> createNotification({
    String? userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await FirebaseHelper.createNotification({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'is_read': false,
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseHelper.markNotificationRead(notificationId);
  }

  Future<void> cancelAll() async => await _notifications.cancelAll();

  void dispose() => _notificationController.close();
}

enum NotificationType { sosAlert, system, reminder }
