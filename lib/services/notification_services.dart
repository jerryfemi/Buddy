import 'dart:io' show Platform;

import 'package:buddy/utils/app_keys.dart';
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

  // Call this  in main.dart
  static Future<void> init() async {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));

    const androidInit = AndroidInitializationSettings('ic_notifications');
    const iosInit = DarwinInitializationSettings();

    final settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifications.initialize(settings: settings);

    // Android: register channels with max importance
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Tasks notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'tasks_channel',
          'Tasks',
          description: 'Reminders for your Tasks',
          importance: Importance.max,
          showBadge: true,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );

      // Events notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'events_channel',
          'Events',
          description: 'Reminders for your Events',
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
  }) async {
    final notifId = _uuidToInt("task-$uuid");
    final channelId = 'tasks_channel';
    final channelName = 'Tasks';
    final channelDescription = 'Reminders for your Tasks';

    await _notifications.zonedSchedule(
      id: notifId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: _createNotificationDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
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
    final notifId = _uuidToInt("pre-event-$uuid");
    final channelId = 'events_channel';
    final channelName = 'Events';
    final channelDescription = 'Pre-reminder for your Events';

    await _notifications.zonedSchedule(
      id: notifId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: _createNotificationDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
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
  }) async {
    final notifId = _uuidToInt("event-$uuid");
    final channelId = 'events_channel';
    final channelName = 'Events';
    final channelDescription = 'Reminders for your Events';
    await _notifications.zonedSchedule(
      id: notifId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: _createNotificationDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
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
    final notifId = _uuidToInt("event-end-$uuid");

    await _notifications.zonedSchedule(
      id: notifId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'events_channel',
          'Events',
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
    await _notifications.cancel(id: _uuidToInt("task-$uuid"));
  }

  static Future<void> cancelEvent(String uuid) async {
    await _notifications.cancel(id: _uuidToInt("event-$uuid"));
  }

  // Cancel all
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  } // Cancel all

  static Future<void> cancelPreEvent(String uuid) async {
    await _notifications.cancel(id: _uuidToInt("pre-event-$uuid"));
  }

  static Future<void> cancelEventEnd(String uuid) async {
    await _notifications.cancel(id: _uuidToInt("event-end-$uuid"));
  }
}

//
NotificationDetails _createNotificationDetails({
  required String channelId,
  required String channelName,
  required String channelDescription,
  bool autoCancel = true,
}) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      icon: 'ic_notifications',
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: false,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      autoCancel: autoCancel,
      enableVibration: true,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}
