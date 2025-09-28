import 'package:buddy/firebase/sync_service/notes_sync_service.dart';
import 'package:buddy/models/note_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../../models/deleted_notes_model.dart';
import '../firestore/deleted_notes_firestore.dart';

class DeletedNotesSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final Box<DeletedNote> deletedNoteBox;

  DeletedNotesSyncService({required this.userId, required this.deletedNoteBox});

  //  Download deleted notes from Firestore → Hive
  Future<void> syncFromFirestore() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('deleted_notes')
        .get();

    for (var doc in snapshot.docs) {
      final firestoreNote = DeletedNoteFirestore.fromMap(doc.id, doc.data());
      await deletedNoteBox.put(doc.id, firestoreNote.toHive());
    }
  }

  //  Push all local deleted notes → Firestore
  Future<void> syncToFirestore() async {
    for (var note in deletedNoteBox.values) {
      final firestoreNote = DeletedNoteFirestore.fromHive(note);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('deleted_notes')
          .doc(note.id)
          .set(firestoreNote.toMap(), SetOptions(merge: true));
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
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('deleted_notes')
        .doc(noteId)
        .delete();
  }

  // move a deleted note here
  Future<void> syncSingleToFireStore(DeletedNote note) async {
    final fireStoreNote = DeletedNoteFirestore.fromHive(note);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('deleted_notes')
        .doc(note.id)
        .set(fireStoreNote.toMap(), SetOptions(merge: true));
  }

  //  Full sync (Firestore ↔ Hive)
  Future<void> fullSync() async {
    await syncFromFirestore();
    await syncToFirestore();
  }
}
