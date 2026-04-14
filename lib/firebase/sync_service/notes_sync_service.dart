import 'package:buddy/firebase/sync_service/deleted_notes_sync_service.dart';
import 'package:buddy/models/deleted_notes_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../../models/note_model.dart';
import '../firestore/notes_firestore.dart';
import 'sync_checkpoint_service.dart';
import 'sync_operation_runner.dart';

class NoteSyncService {
  // Conflict policy: last-write-wins based on Firestore server-side updatedAt.
  static const String conflictPolicy = 'last_write_wins_server_updatedAt';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final Box<Note> noteBox;
  final SyncCheckpointService _checkpointService = SyncCheckpointService();

  NoteSyncService({required this.userId, required this.noteBox});

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _firestore.collection('users').doc(userId).collection('notes');

  // Add or update a note
  Future<void> syncToFirestore(Note note) async {
    final docRef = _notesRef.doc(note.id);
    final noteFirestore = NoteFirestore.fromHive(note);
    final data = noteFirestore.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await SyncOperationRunner.runWithRetry<void>(
      collection: 'notes',
      docId: note.id,
      operation: 'upsert',
      action: () => docRef.set(data, SetOptions(merge: true)),
    );
  }

  // Delete note from Firestore
  Future<void> deleteFromFirestore(String noteId) async {
    final docRef = _notesRef.doc(noteId);
    await SyncOperationRunner.runWithRetry<void>(
      collection: 'notes',
      docId: noteId,
      operation: 'delete',
      action: docRef.delete,
    );
  }

  // move notes to deleted notes
  Future<void> moveToDeleted(
    Note note,
    DeletedNotesSyncService deletedService,
  ) async {
    await SyncOperationRunner.runWithRetry<void>(
      collection: 'notes',
      docId: note.id,
      operation: 'move_to_deleted_delete_source',
      action: () => _notesRef.doc(note.id).delete(),
    );

    final deletedNote = DeletedNote(
      id: note.id,
      content: note.content,
      contentJson: note.contentJson,
      deletedAt: DateTime.now(),
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );

    await deletedService.syncSingleToFireStore(deletedNote);
  }

  // Pull Firestore notes → Hive
  Future<void> syncFromFirestore() async {
    final lastPullAt = await _checkpointService.getLastPullAt(
      userId: userId,
      collection: 'notes',
    );

    Query<Map<String, dynamic>> query = _notesRef;
    if (lastPullAt != null) {
      query = query.where(
        'updatedAt',
        isGreaterThan: Timestamp.fromDate(lastPullAt),
      );
    }

    final snapshot = await query.get();
    final updates = <String, Note>{};

    for (final doc in snapshot.docs) {
      final noteFirestore = NoteFirestore.fromMap(doc.id, doc.data());
      final existingNote = noteBox.get(noteFirestore.id);

      if (existingNote == null ||
          noteFirestore.updatedAt.isAfter(existingNote.updatedAt)) {
        updates[noteFirestore.id] = noteFirestore.toHive();
      }
    }

    if (updates.isNotEmpty) {
      await noteBox.putAll(updates);
    }

    await _checkpointService.markPulledNow(userId: userId, collection: 'notes');
  }

  // Two-way sync
  Future<void> syncAll() async {
    for (final note in noteBox.values) {
      await syncToFirestore(note);
    }

    await syncFromFirestore();
  }
}
