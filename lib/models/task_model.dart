import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  Priority priority;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  final DateTime? reminderTime;

  @HiveField(5)
  bool hasReminder;

  @HiveField(6)
  DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.priority = Priority.low,
    this.isCompleted = false,
    required this.reminderTime,
    required this.hasReminder,
    required this.completedAt,
  });
}

@HiveType(typeId: 3)
enum Priority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}
