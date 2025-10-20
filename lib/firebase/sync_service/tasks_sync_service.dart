import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../models/task_model.dart';
import '../firestore/tasks_firestore.dart';


class TaskSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final Box<Task> taskBox;

  TaskSyncService({required this.userId, required this.taskBox});

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('users').doc(userId).collection('tasks');

  // push hive tasks to firestore
  Future<void> syncToFirestore(Task task) async {
    final docRef = _tasksRef.doc(task.id);
    final taskFirestore = TaskFirestore.fromHive(task);

    await docRef.set(taskFirestore.toMap(), SetOptions(merge: true));
  }

  // Delete task from Firestore
  Future<void> deleteFromFirestore(String taskId) async {
    final docRef = _tasksRef.doc(taskId);
    await docRef.delete();
  }

  // Pull Firestore tasks → Hive
  Future<void> syncFromFirestore() async {

      final snapshot = await _tasksRef.get();
      final updates = <String, Task>{};

      for (var doc in snapshot.docs) {
        final taskFirestore = TaskFirestore.fromMap(doc.id, doc.data());
        final existingTask = taskBox.get(taskFirestore.id);

        if (existingTask == null) {
          updates[taskFirestore.id] = taskFirestore.toHive();
        }
      }

      if (updates.isNotEmpty) {
         taskBox.putAll(updates).catchError((e){});
      }
    }

  // Two-way sync
  Future<void> syncAll() async {

      final uploadFutures = taskBox.values.map((task) {
        return syncToFirestore(task).catchError((e) {
        });
      }).toList();

      await Future.wait([
        Future.wait(uploadFutures),
        syncFromFirestore(),
      ]);
  }
}

