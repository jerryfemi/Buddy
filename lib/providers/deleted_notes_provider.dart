import 'package:buddy/models/note_model.dart';
import 'package:buddy/providers/notes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';

import '../models/deleted_notes_model.dart';

final deletedNotesBoxProvider = Provider<Box<DeletedNote>>(
  (ref) => Hive.box('deletedNotesBox'),
);
final deletedNotesProvider =
    StateNotifierProvider<DeletedNotesNotifier, List<DeletedNote>>((ref) {
      final box = ref.watch(deletedNotesBoxProvider);
      return DeletedNotesNotifier(box, ref);
    });

class DeletedNotesNotifier extends StateNotifier<List<DeletedNote>> {
  final Box<DeletedNote> box;
  final Ref _ref;

  DeletedNotesNotifier(this.box, this._ref) : super(box.values.toList()) {
    purgeExpiredNotes();
  }

  // auto delete notes permanently
  Future<void> purgeExpiredNotes() async {
    await cleanupExpiredNotes();
    box.values.toList();
  }

  // add deleted note here
  Future<void> addDeletedNote(Note note) async {
    final deleted = DeletedNote(
      id: note.id,
      content: note.content,
      contentJson: note.contentJson,
      deletedAt: DateTime.now(),
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );

    await box.put(deleted.id, deleted);
    state = box.values.toList();
  }

  //restore deleted note
  Future<void> restoreNote(String id) async {
    final deleted = box.get(id);
    if (deleted == null) return;
    final originalNote = Note(
      id: deleted.id,
      content: deleted.content,
      contentJson: deleted.contentJson,
      createdAt: deleted.createdAt,
      updatedAt: deleted.updatedAt,
    );
    // add back to active notes
    _ref.read(notesProvider.notifier).restoreNote(originalNote);

    // remove from deleted box
    await box.delete(id);
    state = box.values.toList();
  }

  // permanently delete note from recently deleted

  Future<void> permanentlyDeleteNote(String id) async {
    await box.delete(id);
    state = box.values.toList();
  }

  Future<void> cleanupExpiredNotes() async {
    final now = DateTime.now();

    final toRemove = box.values
        .where((note) {
          return now.difference(note.deletedAt).inDays >= 30;
        })
        .map((n) => n.id)
        .toList();

    if (toRemove.isNotEmpty) {
      await box.deleteAll(toRemove);
    }
    state = box.values.toList();
  }
}
