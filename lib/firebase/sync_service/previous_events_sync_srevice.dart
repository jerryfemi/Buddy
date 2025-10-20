import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../models/previous_events_model.dart';
import '../firestore/previous_events_firestore.dart';

class PreviousEventSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final Box<PreviousEvents> previousEventBox;

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

     docRef.set(eventFirestore.toMap(), SetOptions(merge: true));
  }

  // Delete previous event from Firestore
  Future<void> deleteFromFirestorePermanently(String eventId) async {
    final docRef = _previousEventsRef.doc(eventId);
    await docRef.delete();
  }

  // Pull Firestore previous events → Hive
  Future<void> syncFromFirestore() async {
      final snapshot = await _previousEventsRef.get();
      final updates = <String, PreviousEvents>{};

      for (var doc in snapshot.docs) {
        final eventFirestore = PreviousEventFirestore.fromMap(
          doc.id,
          doc.data(),
        );
        final existingEvent = previousEventBox.get(eventFirestore.id);

        if (existingEvent == null ||
            eventFirestore.startDateTime.isAfter(existingEvent.startDateTime)) {
          updates[eventFirestore.id] = eventFirestore.toHive();
        }
      }

      if (updates.isNotEmpty) {
         previousEventBox.putAll(updates).catchError((e){});
      }

  }

  // Two-way sync
  Future<void> syncAll() async {

      final uploadFutures = previousEventBox.values.map((event) {
        return syncToFirestore(event).catchError((e) {
        });
      }).toList();

       Future.wait([
        Future.wait(uploadFutures),
        syncFromFirestore(),
      ]);
    }
  }
