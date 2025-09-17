import 'package:buddy/models/note_model.dart';
import 'package:buddy/providers/deleted_notes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

final notesBoxProvider = Provider<Box<Note>>((ref) => Hive.box('notesBox'));
final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  final box = ref.watch(notesBoxProvider);
  return NotesNotifier(box, ref);
});

class NotesNotifier extends StateNotifier<List<Note>> {
  final Box<Note> _box;
  final Ref _ref;

  NotesNotifier(this._box, this._ref) : super(_box.values.toList());

  //
  Box<Note> getAllNotes() {
    return _box;
  }

  // restore note
  void restoreNote(Note note) {
    _box.put(note.id, note);
    state = _box.values.toList();
  }

  // add new note
  void addNote({required String content, required String contentJson}) {
    final newNote = Note(
      id: const Uuid().v4(),
      content: content,
      createdAt: DateTime.now(),
      contentJson: contentJson,
      updatedAt: DateTime.now(),
    );

    _box.put(newNote.id, newNote);
    state = _box.values.toList();
  }

  // update existing note
  void updateNote({
    required String id,
    String? title,
    String? content,
    String? contentJson,
  }) {
    final noteIndex = state.indexWhere((n) => n.id == id);
    if (noteIndex == -1) return;
    // note not found

    final currentNote = state[noteIndex];

    final updatedNote = currentNote.copyWith(
      contentJson: contentJson ?? currentNote.contentJson,
      updatedAt: DateTime.now(),
      content: content ?? currentNote.content,
    );

    _box.put(updatedNote.id, updatedNote);
    state = _box.values.toList();
  }

  // delete notes
  void deleteNote(String id, WidgetRef ref) {
    final note = _box.get(id);
    if (note == null) return;

    // move notes to deleted provider
    _ref.watch(deletedNotesProvider.notifier).addDeletedNote(note);

    // delete from notes list
    _box.delete(id);
    state = _box.values.toList();
  }
}
