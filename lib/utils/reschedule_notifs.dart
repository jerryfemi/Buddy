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

     Future.wait(
      events.map((event) async {
        await eventRepo.scheduleEventReminder(event);
        await eventRepo.schedulePreEventReminders(event);
      }),
    );

    // reschedule task notifs
    final tasks = ref.read(tasksProvider);
    final taskRepo = TaskNotificationRepository();

    Future.wait(
      tasks.map((task) async {
        taskRepo.scheduleTaskReminder(task).catchError((e) {});
      }),
    );
  }
}
