import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/task_model.dart';

class TaskFirestore {
  final String id;
  final String title;
  final String priority; // string for Firestore
  final bool isCompleted;
  final DateTime? reminderTime;
  final bool hasReminder;
  final DateTime? completedAt;

  TaskFirestore({
    required this.id,
    required this.title,
    required this.priority,
    required this.isCompleted,
    this.reminderTime,
    required this.hasReminder,
    this.completedAt,
  });

  // From Hive
  factory TaskFirestore.fromHive(Task task) {
    return TaskFirestore(
      id: task.id,
      title: task.title,
      priority: task.priority.name,
      isCompleted: task.isCompleted,
      reminderTime: task.reminderTime,
      hasReminder: task.hasReminder,
      completedAt: task.completedAt,
    );
  }

  // To Hive
  Task toHive() {
    return Task(
      id: id,
      title: title,
      priority: Priority.values.firstWhere(
            (p) => p.name == priority,
        orElse: () => Priority.low,
      ),
      isCompleted: isCompleted,
      reminderTime: reminderTime,
      hasReminder: hasReminder,
      completedAt: completedAt,
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'priority': priority,
      'isCompleted': isCompleted,
      'reminderTime': reminderTime,
      'hasReminder': hasReminder,
      'completedAt': completedAt,
    };
  }

  // From Firestore
  factory TaskFirestore.fromMap(String id, Map<String, dynamic> map) {
    return TaskFirestore(
      id: id,
      title: map['title'] ?? '',
      priority: map['priority'] ?? 'low',
      isCompleted: map['isCompleted'] ?? false,
      reminderTime: map['reminderTime'] != null
          ? (map['reminderTime'] as Timestamp).toDate()
          : null,
      hasReminder: map['hasReminder'] ?? false,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }
}