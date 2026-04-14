import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../models/task_model.dart';
import '../firestore/tasks_firestore.dart';
import 'sync_checkpoint_service.dart';
import 'sync_operation_runner.dart';

class TaskSyncService {
  // Conflict policy: last-write-wins based on Firestore server-side updatedAt.
  static const String conflictPolicy = 'last_write_wins_server_updatedAt';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final Box<Task> taskBox;
  final SyncCheckpointService _checkpointService = SyncCheckpointService();

  TaskSyncService({required this.userId, required this.taskBox});

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('users').doc(userId).collection('tasks');

  // push hive tasks to firestore
  Future<void> syncToFirestore(Task task) async {
    final docRef = _tasksRef.doc(task.id);
    final taskFirestore = TaskFirestore.fromHive(task);
    final data = taskFirestore.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await SyncOperationRunner.runWithRetry<void>(
      collection: 'tasks',
      docId: task.id,
      operation: 'upsert',
      action: () => docRef.set(data, SetOptions(merge: true)),
    );
  }

  // Delete task from Firestore
  Future<void> deleteFromFirestore(String taskId) async {
    final docRef = _tasksRef.doc(taskId);
    await SyncOperationRunner.runWithRetry<void>(
      collection: 'tasks',
      docId: taskId,
      operation: 'delete',
      action: docRef.delete,
    );
  }

  // Pull Firestore tasks → Hive
  Future<void> syncFromFirestore() async {
    final lastPullAt = await _checkpointService.getLastPullAt(
      userId: userId,
      collection: 'tasks',
    );

    Query<Map<String, dynamic>> query = _tasksRef;
    if (lastPullAt != null) {
      query = query.where(
        'updatedAt',
        isGreaterThan: Timestamp.fromDate(lastPullAt),
      );
    }

    final snapshot = await query.get();
    final updates = <String, Task>{};

    for (final doc in snapshot.docs) {
      final taskFirestore = TaskFirestore.fromMap(doc.id, doc.data());
      updates[taskFirestore.id] = taskFirestore.toHive();
    }

    if (updates.isNotEmpty) {
      await taskBox.putAll(updates);
    }

    await _checkpointService.markPulledNow(userId: userId, collection: 'tasks');
  }

  // Two-way sync
  Future<void> syncAll() async {
    for (final task in taskBox.values) {
      await syncToFirestore(task);
    }

    await syncFromFirestore();
  }
}
