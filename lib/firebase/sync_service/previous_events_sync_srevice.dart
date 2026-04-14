import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../models/previous_events_model.dart';
import '../firestore/previous_events_firestore.dart';
import 'sync_checkpoint_service.dart';
import 'sync_operation_runner.dart';

class PreviousEventSyncService {
  // Conflict policy: last-write-wins based on Firestore server-side updatedAt.
  static const String conflictPolicy = 'last_write_wins_server_updatedAt';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final Box<PreviousEvents> previousEventBox;
  final SyncCheckpointService _checkpointService = SyncCheckpointService();

  PreviousEventSyncService({
    required this.userId,
    required this.previousEventBox,
  });

  CollectionReference<Map<String, dynamic>> get _previousEventsRef =>
      _firestore.collection('users').doc(userId).collection('previousEvents');

  // sync preEvents from hive database to firestore
  Future<void> syncToFirestore(PreviousEvents event) async {
    final docRef = _previousEventsRef.doc(event.id);
    final eventFirestore = PreviousEventFirestore.fromHive(event);
    final data = eventFirestore.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await SyncOperationRunner.runWithRetry<void>(
      collection: 'previousEvents',
      docId: event.id,
      operation: 'upsert',
      action: () => docRef.set(data, SetOptions(merge: true)),
    );
  }

  // Delete previous event from Firestore
  Future<void> deleteFromFirestorePermanently(String eventId) async {
    final docRef = _previousEventsRef.doc(eventId);
    await SyncOperationRunner.runWithRetry<void>(
      collection: 'previousEvents',
      docId: eventId,
      operation: 'delete',
      action: docRef.delete,
    );
  }

  Future<void> deleteManyFromFirestorePermanently(List<String> eventIds) async {
    if (eventIds.isEmpty) return;

    final batch = _firestore.batch();
    for (final eventId in eventIds) {
      batch.delete(_previousEventsRef.doc(eventId));
    }

    await SyncOperationRunner.runWithRetry<void>(
      collection: 'previousEvents',
      docId: 'batch:${eventIds.length}',
      operation: 'batch_delete',
      action: batch.commit,
    );
  }

  // Pull Firestore previous events → Hive
  Future<void> syncFromFirestore() async {
    final lastPullAt = await _checkpointService.getLastPullAt(
      userId: userId,
      collection: 'previousEvents',
    );

    Query<Map<String, dynamic>> query = _previousEventsRef;
    if (lastPullAt != null) {
      query = query.where(
        'updatedAt',
        isGreaterThan: Timestamp.fromDate(lastPullAt),
      );
    }

    final snapshot = await query.get();
    final updates = <String, PreviousEvents>{};

    for (final doc in snapshot.docs) {
      final eventFirestore = PreviousEventFirestore.fromMap(doc.id, doc.data());
      updates[eventFirestore.id] = eventFirestore.toHive();
    }

    if (updates.isNotEmpty) {
      await previousEventBox.putAll(updates);
    }

    await _checkpointService.markPulledNow(
      userId: userId,
      collection: 'previousEvents',
    );
  }

  // Two-way sync
  Future<void> syncAll() async {
    for (final event in previousEventBox.values) {
      await syncToFirestore(event);
    }

    await syncFromFirestore();
  }
}
