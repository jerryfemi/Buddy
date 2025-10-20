import 'package:buddy/firebase/sync_service/previous_events_sync_srevice.dart';
import 'package:buddy/models/previous_events_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../models/calendar_event_model.dart';
import '../firestore/calendar_event_firestore.dart';

class CalendarEventSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final Box<CalendarEvent> eventBox;

  CalendarEventSyncService({required this.userId, required this.eventBox});

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('users').doc(userId).collection('events');

  // sync an event from hive database to firestore
  Future<void> syncToFirestore(CalendarEvent event) async {
    final docRef = _eventsRef.doc(event.id);
    final eventFirestore = CalendarEventFirestore.fromHive(event);

    await docRef.set(eventFirestore.toMap(), SetOptions(merge: true));
  }

  // Delete event from Firestore
  Future<void> deleteFromFirestore(String eventId) async {
    final docRef = _eventsRef.doc(eventId);
    await docRef.delete();
  }

  // move to previous Events
  Future<void> moveToPreviousEvents(
    CalendarEvent event,
    PreviousEventSyncService previousService,
  ) async {
    await _eventsRef.doc(event.id).delete();

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

      final snapshot = await _eventsRef.get();
      final updates = <String, CalendarEvent>{};

      for (var doc in snapshot.docs) {
        final eventFirestore = CalendarEventFirestore.fromMap(
          doc.id,
          doc.data(),
        );
        final existingEvent = eventBox.get(eventFirestore.id);

        if (existingEvent == null ||
            eventFirestore.startDateTime.isAfter(existingEvent.startDateTime)) {
          updates[eventFirestore.id] = eventFirestore.toHive();
        }
      }

      if (updates.isNotEmpty) {
        await eventBox.putAll(updates);
      }
    }

  // Two-way sync
  Future<void> syncAll() async {
    final uploadFutures = eventBox.values.map((event) {
      return syncToFirestore(event).catchError((e) {});
    }).toList();

     Future.wait([Future.wait(uploadFutures), syncFromFirestore()]);
  }
}
