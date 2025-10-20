import 'package:buddy/firebase/sync_service/tasks_sync_service.dart';
import 'package:buddy/models/calendar_event_model.dart';
import 'package:buddy/models/task_model.dart';
import 'package:buddy/providers/auth_provider.dart';
import 'package:buddy/providers/previous_events_provider.dart';
import 'package:buddy/services/task_notifications_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:uuid/uuid.dart';

// getting access to the tasks Hive box
final tasksBoxProvider = Provider<Box<Task>>(
  (ref) => Hive.box<Task>('tasksBox'),
);

// tasks sync service provider
final tasksSyncService = Provider<TaskSyncService?>((ref) {
  final user = ref.watch(authStateProvider).value;
  final box = ref.watch(tasksBoxProvider);

  if (user == null) return null;
  return TaskSyncService(userId: user.uid, taskBox: box);
});

// pass access to the taskNotifier
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  // get the tasks hive box
  final box = ref.watch(tasksBoxProvider);
  final tasksService = ref.watch(tasksSyncService);
  return TasksNotifier(box, ref, tasksService);
});

class TasksNotifier extends StateNotifier<List<Task>> {
  final Box<Task> _box;
  final TaskSyncService? _syncService;
  final Ref _ref;
  late final VoidCallback listener;

  TasksNotifier(this._box, this._ref, this._syncService) : super([]) {
    loadTasks();

    // listen for hive changes
    listener = () {
      if (mounted) {
        state = _box.values.toList();
      }
    };

    // add listener
    _box.listenable().addListener(listener);
  }

  @override
  void dispose() {
    // remove listener
    _box.listenable().removeListener(listener);
    super.dispose();
  }

  // repository for task notifications
  final taskNotificationRepo = TaskNotificationRepository();

  // initialize tasks
  Future<void> loadTasks() async {
    final initial = _box.values.toList();
    if (mounted) state = initial;
  }

  // add tasks
  void createTask({
    required String title,
    String description = '',
    Priority priority = Priority.low,
    DateTime? reminderTime,
  }) {
    final newTask = Task(
      id: Uuid().v4(),
      title: title,
      hasReminder: reminderTime != null,
      reminderTime: reminderTime,
      priority: priority,
      isCompleted: false,
      completedAt: null,
    );

    _box.put(newTask.id, newTask);
    // schedule notifications if reminder is set
    if (reminderTime != null) {
      taskNotificationRepo.scheduleTaskReminder(newTask);
    }
    state = _box.values.toList();

    // sync to firestore
    if (_syncService != null) {
      _syncService.syncToFirestore(newTask).catchError((error){});
    }
  }

  // toggle task
  void toggleTask(String id) {
    final task = _box.get(id);

    if (task != null) {
      // Toggle the task's completion status
      task.isCompleted = !task.isCompleted;

      if (task.isCompleted) {
        //  Task just got completed — mark timestamp
        task.completedAt = DateTime.now();

        //  Cancel reminder notifications (if any)
        if (task.hasReminder) {
          taskNotificationRepo.cancelTaskReminder(task.id);
        }
      } else {
        task.completedAt = null;

        // Re-schedule reminder if still valid and in the future
        if (task.hasReminder &&
            task.reminderTime != null &&
            task.reminderTime!.isAfter(DateTime.now())) {
          taskNotificationRepo.scheduleTaskReminder(task);
        }
      }

      // Persist changes to Hive
      task.save();

      // Update state so UI refreshes
      state = _box.values.toList();
    }
  }

  // auto deleteCompletedTasks
  void cleanupCompletedTasks() {
    final now = DateTime.now();
    final toRemove = _box.values
        .where(
          (task) =>
              task.isCompleted &&
              task.completedAt != null &&
              now.difference(task.completedAt!).inHours >= 24,
        )
        .toList();

    if (toRemove.isEmpty) return;
    for (final task in toRemove) {
      final preEventTask = CalendarEvent(
        id: task.id,
        startDateTime: task.completedAt!,
        endDateTime: task.completedAt!,
        title: task.title,
      );
      _ref
          .read(previousEventsProvider.notifier)
          .addPreviousEvents(preEventTask);
      _box.delete(task.id);

      if (_syncService != null) {
        _syncService.deleteFromFirestore(task.id).catchError((error){});
      }
    }
    state = _box.values.toList();
  }

  // delete task
  void deleteTask(String id) {
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
      _ref
          .read(previousEventsProvider.notifier)
          .addPreviousEvents(preEventTask);
      _box.delete(id);
      // cancel notifications if reminders exists
      state = _box.values.toList();
      taskNotificationRepo.cancelTaskReminder(id);

      // delete from firestore
      if (_syncService != null) {
        _syncService.deleteFromFirestore(task.id).catchError((error){});
      }
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
