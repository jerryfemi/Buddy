import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static int _uuidToInt(String uuid) => uuid.hashCode & 0x7FFFFFFF;

  // Call this ONCE in main.dart
  static Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    final pending = await _notifications.pendingNotificationRequests();
    print("📋 Pending Notifications (${pending.length}):");
    for (final p in pending) {
      print("• id=${p.id}, title=${p.title}, body=${p.body}");
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    final settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload ?? '';
        print("📩 Notification tapped → $payload");
      },
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

    await _requestBatteryOptimizationExemption();
    await _requestNotificationPermission();
  }

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
          print("⚠️ Exact alarm permission denied, opening settings...");
          await openAppSettings();
        }
      }
    }
  }


  static Future<void> _requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();

    // Check if we already asked before
    final hasPrompted = prefs.getBool('battery_optimization_prompted') ?? false;
    if (hasPrompted) {
      print("🔋 Battery optimization prompt skipped (already shown).");
      return;
    }

    final isBatteryOptimizationDisabled =
        await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;

    if (!isBatteryOptimizationDisabled) {
      print("🔋 Showing battery optimization settings...");
      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
    } else {
      print("✅ Battery optimization already disabled.");
    }

    // Store flag so we don't keep prompting
    await prefs.setBool('battery_optimization_prompted', true);
  }


  // Task reminder with enhanced priority
  static Future<void> scheduleTaskReminder({
    required String uuid,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool isCritical = false,
  }) async {
    final notifId = _uuidToInt("task-$uuid");
    final channelId = isCritical ? 'critical_reminders' : 'reminders_channel';

    await _notifications.zonedSchedule(
      notifId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Reminders',
          channelDescription: 'Task reminders',
          importance: Importance.max,
          // Changed to max
          priority: Priority.max,
          // Changed to max
          autoCancel: true,
          enableVibration: true,
          enableLights: true,
          fullScreenIntent: isCritical,
          // Shows as heads-up for critical
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      payload: "task:$uuid",
    );

    print(
      "⏰ Scheduled $title for $scheduledTime (${tz.local.name}) → id=$notifId",
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
    final notifId = _uuidToInt("event-$uuid");
    final channelId = isCritical ? 'critical_reminders' : 'reminders_channel';

    await _notifications.zonedSchedule(
      notifId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Reminders',
          channelDescription: 'Event reminders',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          enableLights: true,
          fullScreenIntent: isCritical,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.event,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      payload: "event:$uuid",
    );

    print(
      "⏰ Scheduled $title for $scheduledTime (${tz.local.name}) → id=$notifId",
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
    final notifId = _uuidToInt("schedule-$uuid");
    final channelId = isCritical ? 'critical_reminders' : 'reminders_channel';

    await _notifications.zonedSchedule(
      notifId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Reminders',
          channelDescription: 'Event reminders',
          importance: Importance.max,
          priority: Priority.max,
          autoCancel: false,
          enableVibration: true,
          enableLights: true,
          fullScreenIntent: isCritical,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.event,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      payload: "event:$uuid",
    );

    print(
      "⏰ Scheduled $title for $scheduledTime (${tz.local.name}) → id=$notifId",
    );
  }

  // Schedule event end
  static Future<void> scheduleEventEnd({
    required String uuid,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final notifId = _uuidToInt("event_end-$uuid");

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

    print(
      "⏰ Scheduled $title for $scheduledTime (${tz.local.name}) → id=$notifId",
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
