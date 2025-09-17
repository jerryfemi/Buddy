
import 'package:buddy/models/task_model.dart';

import 'notification_services.dart';

class TaskNotificationRepository {
  // Schedule a one-off reminder for this task (if it has one)
  Future<void> scheduleTaskReminder(Task task) async {
    if (task.hasReminder && task.reminderTime != null) {
      await NotificationService.scheduleTaskReminder(
        title: "Task Reminder",
        body: task.title,
        scheduledTime: task.reminderTime!,
        uuid: task.id,
      );
    }
  }

  // Cancel a reminder when task is deleted or completed
  Future<void> cancelTaskReminder(String id) async {
    await NotificationService.cancelTask(id);
  }
}
