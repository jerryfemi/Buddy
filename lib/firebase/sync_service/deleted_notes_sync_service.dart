import 'package:buddy/firebase/sync_service/notes_sync_service.dart';
import 'package:buddy/models/note_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../../models/deleted_notes_model.dart';
import '../firestore/deleted_notes_firestore.dart';
import 'sync_checkpoint_service.dart';
import 'sync_operation_runner.dart';

class DeletedNotesSyncService {
  // Conflict policy: last-write-wins based on Firestore server-side updatedAt.
  static const String conflictPolicy = 'last_write_wins_server_updatedAt';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final Box<DeletedNote> deletedNoteBox;
  final SyncCheckpointService _checkpointService = SyncCheckpointService();

  DeletedNotesSyncService({required this.userId, required this.deletedNoteBox});

  //  Download deleted notes from Firestore → Hive
  Future<void> syncFromFirestore() async {
    final lastPullAt = await _checkpointService.getLastPullAt(
      userId: userId,
      collection: 'deleted_notes',
    );

    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(userId)
        .collection('deleted_notes');

    if (lastPullAt != null) {
      query = query.where(
        'updatedAt',
        isGreaterThan: Timestamp.fromDate(lastPullAt),
      );
    }

    final snapshot = await query.get();
    final updates = <String, DeletedNote>{};

    for (final doc in snapshot.docs) {
      final firestoreNote = DeletedNoteFirestore.fromMap(doc.id, doc.data());
      updates[doc.id] = firestoreNote.toHive();
    }

    if (updates.isNotEmpty) {
      await deletedNoteBox.putAll(updates);
    }

    await _checkpointService.markPulledNow(
      userId: userId,
      collection: 'deleted_notes',
    );
  }

  //  Push all local deleted notes → Firestore
  Future<void> syncToFirestore() async {
    for (final note in deletedNoteBox.values) {
      final firestoreNote = DeletedNoteFirestore.fromHive(note);
      final data = firestoreNote.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await SyncOperationRunner.runWithRetry<void>(
        collection: 'deleted_notes',
        docId: note.id,
        operation: 'upsert',
        action: () => _firestore
            .collection('users')
            .doc(userId)
            .collection('deleted_notes')
            .doc(note.id)
            .set(data, SetOptions(merge: true)),
      );
    }
  }

  // restore deleted notes
  Future<void> restoreFromDeleted(
    DeletedNote deletedNote,
    NoteSyncService notesService,
  ) async {
    // remove from collection
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('deleted_notes')
        .doc(deletedNote.id)
        .delete();

    // add back to notes
    final restoredNote = Note(
      id: deletedNote.id,
      content: deletedNote.content,
      createdAt: deletedNote.createdAt,
      contentJson: deletedNote.contentJson,
      updatedAt: deletedNote.updatedAt,
    );

    await notesService.syncToFirestore(restoredNote);
  }

  // delete permanently
  Future<void> deletePermanently(String noteId) async {
    // delete from collection
    await SyncOperationRunner.runWithRetry<void>(
      collection: 'deleted_notes',
      docId: noteId,
      operation: 'delete',
      action: () => _firestore
          .collection('users')
          .doc(userId)
          .collection('deleted_notes')
          .doc(noteId)
          .delete(),
    );
  }

  Future<void> deleteManyPermanently(List<String> noteIds) async {
    if (noteIds.isEmpty) return;

    final batch = _firestore.batch();
    for (final noteId in noteIds) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('deleted_notes')
          .doc(noteId);
      batch.delete(docRef);
    }

    await SyncOperationRunner.runWithRetry<void>(
      collection: 'deleted_notes',
      docId: 'batch:${noteIds.length}',
      operation: 'batch_delete',
      action: batch.commit,
    );
  }

  // move a deleted note here
  Future<void> syncSingleToFireStore(DeletedNote note) async {
    final fireStoreNote = DeletedNoteFirestore.fromHive(note);
    final data = fireStoreNote.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await SyncOperationRunner.runWithRetry<void>(
      collection: 'deleted_notes',
      docId: note.id,
      operation: 'upsert_single',
      action: () => _firestore
          .collection('users')
          .doc(userId)
          .collection('deleted_notes')
          .doc(note.id)
          .set(data, SetOptions(merge: true)),
    );
  }

  //  Full sync (Firestore ↔ Hive)
  Future<void> fullSync() async {
    await syncToFirestore();
    await syncFromFirestore();
  }
}
