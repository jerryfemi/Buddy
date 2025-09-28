import 'dart:ui';

import 'package:buddy/firebase/sync_service/notes_sync_service.dart';
import 'package:buddy/models/note_model.dart';
import 'package:buddy/providers/auth_provider.dart';
import 'package:buddy/providers/deleted_notes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:uuid/uuid.dart';

import '../firebase/sync_service/deleted_notes_sync_service.dart';

// notes hive box provider
final notesBoxProvider = Provider<Box<Note>>((ref) => Hive.box('notesBox'));

// notes sync service provider
final notesSyncServiceProvider = Provider<NoteSyncService?>((ref) {
  final user = ref.watch(authStateProvider).value;
  final box = ref.watch(notesBoxProvider);

  if (user == null) return null;

  return NoteSyncService(userId: user.uid, noteBox: box);
});

// deleted notes sync service provider
final deletedNotesSyncServiceProvider = Provider<DeletedNotesSyncService?>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  final box = ref.watch(deletedNotesBoxProvider);

  if (user == null) return null;

  return DeletedNotesSyncService(userId: user.uid, deletedNoteBox: box);
});

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  final box = ref.watch(notesBoxProvider);
  final notesService = ref.watch(notesSyncServiceProvider);
  final deletedService = ref.watch(deletedNotesSyncServiceProvider);
  return NotesNotifier(box, ref, notesService, deletedService);
});

class NotesNotifier extends StateNotifier<List<Note>> {
  final Box<Note> _box;
  final NoteSyncService? _syncService;
  final DeletedNotesSyncService? _deletedNotesSyncService;
  final Ref _ref;
  late final VoidCallback listener;

  NotesNotifier(
    this._box,
    this._ref,
    this._syncService,
    this._deletedNotesSyncService,
  ) : super(_box.values.toList()) {

    // listen for hive changes
    listener = () {
      if (mounted) {
        state = _box.values.toList();
      }
    };

    // add listener
    _box.listenable().addListener(listener);
  }

  @override
  void dispose() {
    // remove listener
    _box.listenable().removeListener(listener);
    super.dispose();
  }

  //

  // restore note
  Future<void> restoreNote(Note note) async {
    await _box.put(note.id, note);
    state = _box.values.toList();
  }

  // add new note
  Future<void> addNote({
    required String content,
    required String contentJson,
  }) async {
    final newNote = Note(
      id: const Uuid().v4(),
      content: content,
      createdAt: DateTime.now(),
      contentJson: contentJson,
      updatedAt: DateTime.now(),
    );

    _box.put(newNote.id, newNote);

    state = _box.values.toList();

    // sync to fire store
    if (_syncService != null) {
      await _syncService.syncToFirestore(newNote);
    }
  }

  // update existing note
  Future<void> updateNote({
    required String id,
    String? title,
    String? content,
    String? contentJson,
  }) async {
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

    if (_syncService != null) {
      await _syncService.syncToFirestore(updatedNote);
    }
  }

  // delete notes
  Future<void> deleteNote(String id, WidgetRef ref) async {
    final note = _box.get(id);
    if (note == null) return;

    // move notes to deleted provider
    _ref.read(deletedNotesProvider.notifier).addDeletedNote(note);

    // delete from notes list
    _box.delete(id);
    state = _box.values.toList();

    // move to deleted notes firestore
    if (_syncService != null && _deletedNotesSyncService != null) {
      await _syncService.moveToDeleted(note, _deletedNotesSyncService);
    }
  }
}
