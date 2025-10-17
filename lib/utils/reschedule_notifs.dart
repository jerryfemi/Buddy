import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calendar_event_provider.dart';
import '../providers/tasks_provider.dart';
import '../services/events_notifications_repository.dart';
import '../services/task_notifications_repository.dart';

class RescheduleNotifs {
  final WidgetRef ref;

  RescheduleNotifs(this.ref);

  Future<void> run() async {
    // reschedule events notifs
    final events = ref.read(eventsProvider);
    final eventRepo = EventsNotificationsRepository();

    await Future.wait(
      events.map((event) async {
        try {
          await eventRepo.scheduleEventReminder(event);
          await eventRepo.schedulePreEventReminders(event);
        } catch (e) {
          print('failed to reschedule event ${event.id} : $e');
        }
      }),
    );

    // reschedule task notifs
    final tasks = ref.read(tasksProvider);
    final taskRepo = TaskNotificationRepository();

    await Future.wait(
      tasks.map((task) async {
        try {
          await taskRepo.scheduleTaskReminder(task);
        } catch (e) {
          print('failed to reschedule task ${task.title} : $e');
        }
      }),
    );
  }
}
