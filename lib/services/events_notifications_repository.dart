import 'package:buddy/models/calendar_event_model.dart';

import 'notification_services.dart';

class EventsNotificationsRepository {
  // pre event reminder
  Future<void> schedulePreEventReminders(CalendarEvent event) async {
    for (final minutes in event.reminders) {
      final reminderTime = event.startDateTime.subtract(
        Duration(minutes: minutes),
      );

      if (reminderTime.isAfter(DateTime.now())) {
        await NotificationService.preEventReminder(
          uuid: '${event.id}-$minutes',
          title: 'Upcoming Event',
          body: '${event.title} starts in $minutes minutes',
          scheduledTime: reminderTime,
        );
      }
    }
  }

  // Schedule a one-off reminder for this task (if it has one)
  Future<void> scheduleEventReminder(CalendarEvent event) async {
    await NotificationService.scheduleEventReminder(
      title: "Event Reminder",
      body: event.title,
      scheduledTime: event.startDateTime,
      uuid: event.id,
    );

    // event as ended notification.
    await NotificationService.scheduleEventEnd(
      uuid: event.id,
      title: 'Event Ended',
      body: '${event.title} has ended',
      scheduledTime: event.endDateTime,
    );
  }

  // Cancel a reminder when task is deleted or completed
  Future<void> cancelEventReminder(CalendarEvent event) async {
    // cancel main event
    await NotificationService.cancelEvent(event.id);
    await NotificationService.cancelEventEnd(event.id);

    // cancel pre event reminders
    for (final minutes in event.reminders) {
      final preEventUid = '${event.id}-$minutes';
      await NotificationService.cancelPreEvent(preEventUid);
    }
  }
}
