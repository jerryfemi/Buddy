import 'package:buddy/models/calendar_event_model.dart';
import 'package:buddy/models/task_model.dart';
import 'package:buddy/providers/previous_events_provider.dart';
import 'package:buddy/services/task_notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

// getting access to the tasks Hive box
final tasksBoxProvider = Provider<Box<Task>>(
  (ref) => Hive.box<Task>('tasksBox'),
);
// pass access to the taskNotifier
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  // get the tasks hive box
  final box = ref.watch(tasksBoxProvider);
  // pass the task hive box to the tasks notifier
  return TasksNotifier(box, ref);
});

class TasksNotifier extends StateNotifier<List<Task>> {
  final Box<Task> _box;
  final Ref _ref;

  TasksNotifier(this._box, this._ref) : super(_box.values.toList());

  // repository for task notifications
  final taskNotificationRepo = TaskNotificationRepository();

  // add tasks
  Future<void> createTask({
    required String title,
    String description = '',
    Priority priority = Priority.low,
    DateTime? reminderTime,
  }) async {
    final newTask = Task(
      id: Uuid().v4(),
      title: title,
      hasReminder: reminderTime != null,
      reminderTime: reminderTime,
      priority: priority,
      isCompleted: false,
      completedAt: null,
    );
    // if the only task in the box is the default task, delete it.
    if (_box.length == 1 && _box.getAt(0)?.title == 'Add Task') {
      _box.deleteAt(0);
    }
    await _box.put(newTask.id, newTask);

    // schedule notifications if reminder is set
    await taskNotificationRepo.scheduleTaskReminder(newTask);
    state = _box.values.toList();
  }

  // toggle task
  Future<void> toggleTask(String id) async {
    final task = _box.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      await task.save();
      if (task.isCompleted) {
        task.completedAt = DateTime.now();
      } else {
        task.completedAt = null;
      }
      state = _box.values.toList();
    }
  }

  // auto deleteCompletedTasks
  Future<void> cleanupCompletedTasks() async {
    final now = DateTime.now();
    final toRemove = _box.values.where(
      (task) =>
          task.isCompleted &&
          task.completedAt != null &&
          now.difference(task.completedAt!).inHours >= 24,
    );

    for (final task in toRemove) {
      final preEventTask = CalendarEvent(
        id: task.id,
        startDateTime: task.completedAt!,
        endDateTime: task.completedAt!,
        title: task.title,
      );
      await _ref
          .read(previousEventsProvider.notifier)
          .addPreviousEvents(preEventTask);
      await _box.delete(task.id);
      state = _box.values.toList();
    }
  }

  // delete task
  Future<void> deleteTask(String id) async {
    final task = _box.get(id);
    if (task != null) {
      final eventTime = task.isCompleted && task.completedAt != null
          ? task.completedAt!
          : DateTime.now();
      final preEventTask = CalendarEvent(
        id: task.id,
        startDateTime: eventTime,
        endDateTime: eventTime,
        title: task.title,
      );
      await _ref
          .read(previousEventsProvider.notifier)
          .addPreviousEvents(preEventTask);
      // cancel notifications if reminders exists
      await taskNotificationRepo.cancelTaskReminder(id);
      await _box.delete(id);
      state = _box.values.toList();
    }
  }

  // tasks that have reminders
  List<Task> get taskWithReminders =>
      state.where((t) => t.hasReminder && t.reminderTime != null).toList();

  // get upcoming task with reminders
  List<Task> get upcomingTasks {
    final now = DateTime.now();
    final upcoming = state
        .where(
          (t) =>
              t.hasReminder &&
              t.reminderTime != null &&
              t.reminderTime!.isAfter(now),
        )
        .toList();
    upcoming.sort((a, b) => a.reminderTime!.compareTo(b.reminderTime!));
    return upcoming;
  }

  // Task completion as a fraction
  double get completionFraction {
    if (state.isEmpty) return 0.0;
    final completed = state.where((t) => t.isCompleted).length;
    return completed / state.length;
  }
}
