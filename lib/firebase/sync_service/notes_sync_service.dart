import 'package:buddy/firebase/sync_service/deleted_notes_sync_service.dart';
import 'package:buddy/models/deleted_notes_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../../models/note_model.dart';
import '../firestore/notes_firestore.dart';

class NoteSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final Box<Note> noteBox;

  NoteSyncService({required this.userId, required this.noteBox});

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _firestore.collection('users').doc(userId).collection('notes');

  // Add or update a note
  Future<void> syncToFirestore(Note note) async {
    final docRef = _notesRef.doc(note.id);
    final noteFirestore = NoteFirestore.fromHive(note);

    await docRef.set(noteFirestore.toMap(), SetOptions(merge: true));
  }

  // Delete note from Firestore
  Future<void> deleteFromFirestore(String noteId) async {
    final docRef = _notesRef.doc(noteId);
    await docRef.delete();
  }

  // move notes to deleted notes
  Future<void> moveToDeleted(
    Note note,
    DeletedNotesSyncService deletedService,
  ) async {
    await _notesRef.doc(note.id).delete();

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
    try {
      final snapshot = await _notesRef.get();
      final updates = <String, Note>{};

      for (var doc in snapshot.docs) {
        final noteFirestore = NoteFirestore.fromMap(doc.id, doc.data());
        final existingNote = noteBox.get(noteFirestore.id);

        if (existingNote == null ||
            noteFirestore.updatedAt.isAfter(existingNote.updatedAt)) {
          noteBox.put(noteFirestore.id, noteFirestore.toHive());
        }
      }

      if (updates.isNotEmpty) {
        await noteBox.putAll(updates);
      }
    } catch (e) {
      print(' NOTE SYNC FROM FIRESTORE ERROR: $e');
    }
  }

  // Two-way sync
  Future<void> syncAll() async {
    try {
      final uploadFutures = noteBox.values.map((note) {
        return syncToFirestore(note).catchError((e) {
          print('⚠️ Failed to sync note ${note.id}: $e');
        });
      }).toList();

      await Future.wait([
        Future.wait(uploadFutures),
        syncFromFirestore(),
      ]);
    } catch (e) {
      print('⚠️ Note syncAll error: $e');
    }
  }
}
