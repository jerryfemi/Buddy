import 'dart:io' show Platform;

import 'package:buddy/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static int _uuidToInt(String uuid) {
    final cleaned = uuid.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    final part = cleaned.substring(0, 8);
    return int.parse(part, radix: 16) & 0x7FFFFFFF;
  }

  // Call this ONCE in main.dart|
  static Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidInit = AndroidInitializationSettings('ic_notifications');
    const iosInit = DarwinInitializationSettings();

    final settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {},
    );

    // Android: register channels with max importance
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Main channel with MAX importance for better reliability
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'reminders_channel',
          'Reminders',
          description: 'Task and event reminders',
          importance: Importance.max,
          // Changed to max
          showBadge: true,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );

      // Create a high-priority channel for critical notifications
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'critical_reminders',
          'Critical Reminders',
          description: 'High priority notifications',
          importance: Importance.max,
          showBadge: true,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );
    }

    // await _requestBatteryOptimizationExemption();
    await _requestNotificationPermission();
  } // INIT

  // Runtime permission request
  static Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    if (Platform.isAndroid) {
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (!alarmStatus.isGranted) {
        await Permission.scheduleExactAlarm.request();

        final stillDenied = await Permission.scheduleExactAlarm.status;
        if (!stillDenied.isGranted) {
          final context = navigatorKey.currentContext;

          if (context != null && context.mounted) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Allow Exact Alarm'),
                content: Text(
                  'To ensure your reminders trigger on this time,'
                  "please enable Exact alarm permission in settings",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await openAppSettings();
                    },
                    child: Text('open Settings'),
                  ),
                ],
              ),
            );
          }
        }
      }
    }
  }

  // static Future<void> _requestBatteryOptimizationExemption() async {
  //   if (!Platform.isAndroid) return;
  //
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   // Check if we already asked before
  //   final hasPrompted = prefs.getBool('battery_optimization_prompted') ?? false;
  //   if (hasPrompted) {
  //     return;
  //   }
  //
  //   final isBatteryOptimizationDisabled =
  //       await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;
  //
  //   if (!isBatteryOptimizationDisabled) {
  //     await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
  //   }
  //
  //   // Store flag so we don't keep prompting
  //   await prefs.setBool('battery_optimization_prompted', true);
  // }

  // Task reminder with enhanced priority
  static Future<void> scheduleTaskReminder({
    required String uuid,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool isCritical = false,
  }) async {
    final notifId = _uuidToInt(uuid);
    final channelId = isCritical ? 'critical_reminders' : 'reminders_channel';
    final channelName = isCritical ? 'Critical Reminders' : 'Reminders';
    final channelDescription = isCritical
        ? 'High priority notifications'
        : 'Task and event reminders';

    await _notifications.zonedSchedule(
      notifId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _createNotificationDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
        isCritical: isCritical,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      payload: "task:$uuid",
    );
  }

  // Pre event reminder with enhanced priority
  static Future<void> preEventReminder({
    required String uuid,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool isCritical = false,
  }) async {
    final notifId = _uuidToInt(uuid);
    final channelId = isCritical ? 'critical_reminders' : 'reminders_channel';
    final channelName = isCritical ? 'Critical Reminders' : 'Reminders';
    final channelDescription = isCritical
        ? 'High priority notifications'
        : 'Event reminders';

    await _notifications.zonedSchedule(
      notifId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _createNotificationDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
        isCritical: isCritical,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      payload: "event:$uuid",
    );
  }

  // Event reminder with enhanced priority
  static Future<void> scheduleEventReminder({
    required String uuid,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool isCritical = false,
  }) async {
    final notifId = _uuidToInt(uuid);
    final channelId = isCritical ? 'critical_reminders' : 'reminders_channel';
    final channelName = isCritical ? 'Critical Reminders' : 'Reminders';
    final channelDescription = isCritical
        ? 'High priority notifications'
        : 'Event reminders';
    await _notifications.zonedSchedule(
      notifId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _createNotificationDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
        isCritical: isCritical,
        autoCancel: false,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      payload: "event:$uuid",
    );
  }

  // Schedule event end
  static Future<void> scheduleEventEnd({
    required String uuid,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final notifId = _uuidToInt(uuid) + 1;

    await _notifications.zonedSchedule(
      notifId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Reminders',
          channelDescription: 'Auto cleanUp for events end',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      payload: "event:$uuid",
    );
  }

  // Cancel by UUID (with prefix)
  static Future<void> cancelTask(String uuid) async {
    await _notifications.cancel(_uuidToInt("task-$uuid"));
  }

  static Future<void> cancelEvent(String uuid) async {
    await _notifications.cancel(_uuidToInt("event-$uuid"));
  }

  // Cancel all
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  } // Cancel all

  static Future<void> cancelPreEvent(String uuid) async {
    await _notifications.cancel(_uuidToInt("event-$uuid"));
  }

  // Simple test notification for debugging
  static Future<void> showTestNotification() async {
    await _notifications.show(
      999999,
      'Test Notification',
      'If you see this, notifications are working!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'critical_reminders',
          'Critical Reminders',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          enableVibration: true,
          enableLights: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

//
NotificationDetails _createNotificationDetails({
  required String channelId,
  required String channelName,
  required String channelDescription,
  required bool isCritical,
  bool autoCancel = true, // Default to true
}) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      icon: 'ic_notifications',
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: isCritical,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      autoCancel: autoCancel,
      // Use the parameter here
      enableVibration: true,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}
