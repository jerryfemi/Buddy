import 'package:buddy/firebase/sync_service/previous_events_sync_srevice.dart';
import 'package:buddy/models/previous_events_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../models/calendar_event_model.dart';
import '../firestore/calendar_event_firestore.dart';
import 'sync_checkpoint_service.dart';
import 'sync_operation_runner.dart';

class CalendarEventSyncService {
  // Conflict policy: last-write-wins based on Firestore server-side updatedAt.
  static const String conflictPolicy = 'last_write_wins_server_updatedAt';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final Box<CalendarEvent> eventBox;
  final SyncCheckpointService _checkpointService = SyncCheckpointService();

  CalendarEventSyncService({required this.userId, required this.eventBox});

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('users').doc(userId).collection('events');

  // sync an event from hive database to firestore
  Future<void> syncToFirestore(CalendarEvent event) async {
    final docRef = _eventsRef.doc(event.id);
    final eventFirestore = CalendarEventFirestore.fromHive(event);
    final data = eventFirestore.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await SyncOperationRunner.runWithRetry<void>(
      collection: 'events',
      docId: event.id,
      operation: 'upsert',
      action: () => docRef.set(data, SetOptions(merge: true)),
    );
  }

  // Delete event from Firestore
  Future<void> deleteFromFirestore(String eventId) async {
    final docRef = _eventsRef.doc(eventId);
    await SyncOperationRunner.runWithRetry<void>(
      collection: 'events',
      docId: eventId,
      operation: 'delete',
      action: docRef.delete,
    );
  }

  // move to previous Events
  Future<void> moveToPreviousEvents(
    CalendarEvent event,
    PreviousEventSyncService previousService,
  ) async {
    await SyncOperationRunner.runWithRetry<void>(
      collection: 'events',
      docId: event.id,
      operation: 'move_to_previous_delete_source',
      action: () => _eventsRef.doc(event.id).delete(),
    );

    final prevEvents = PreviousEvents(
      id: event.id,
      title: event.title,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
    );

    await previousService.syncToFirestore(prevEvents);
  }

  // Pull Firestore events → Hive
  Future<void> syncFromFirestore() async {
    final lastPullAt = await _checkpointService.getLastPullAt(
      userId: userId,
      collection: 'events',
    );

    Query<Map<String, dynamic>> query = _eventsRef;
    if (lastPullAt != null) {
      query = query.where(
        'updatedAt',
        isGreaterThan: Timestamp.fromDate(lastPullAt),
      );
    }

    final snapshot = await query.get();
    final updates = <String, CalendarEvent>{};

    for (final doc in snapshot.docs) {
      final eventFirestore = CalendarEventFirestore.fromMap(doc.id, doc.data());
      updates[eventFirestore.id] = eventFirestore.toHive();
    }

    if (updates.isNotEmpty) {
      await eventBox.putAll(updates);
    }

    await _checkpointService.markPulledNow(
      userId: userId,
      collection: 'events',
    );
  }

  // Two-way sync
  Future<void> syncAll() async {
    for (final event in eventBox.values) {
      await syncToFirestore(event);
    }

    await syncFromFirestore();
  }
}
