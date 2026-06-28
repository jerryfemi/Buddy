import 'dart:ui';

import 'package:buddy/firebase/sync_service/deleted_notes_sync_service.dart';
import 'package:buddy/models/note_model.dart';
import 'package:buddy/providers/auth_provider.dart';
import 'package:buddy/providers/notes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
\import 'package:hive_flutter/adapters.dart';

import '../firebase/sync_service/notes_sync_service.dart';
import '../models/deleted_notes_model.dart';

final deletedNotesBoxProvider = Provider<Box<DeletedNote>>(
  (ref) => Hive.box('deletedNotesBox'),
);

// deleted notes sync service provider
final deletedNotesSyncServiceProvider = Provider<DeletedNotesSyncService?>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  final box = ref.watch(deletedNotesBoxProvider);

  if (user == null) return null;
  return DeletedNotesSyncService(userId: user.uid, deletedNoteBox: box);
});

//  notes sync service provider
final noteSyncServiceProvider = Provider<NoteSyncService?>((ref) {
  final user = ref.watch(authStateProvider).value;
  final box = ref.watch(notesBoxProvider);

  if (user == null) return null;
  return NoteSyncService(userId: user.uid, noteBox: box);
});

final deletedNotesProvider =
    StateNotifierProvider<DeletedNotesNotifier, List<DeletedNote>>((ref) {
      final box = ref.watch(deletedNotesBoxProvider);
      final deletedNotesService = ref.watch(deletedNotesSyncServiceProvider);
      final notesService = ref.watch(notesSyncServiceProvider);
      return DeletedNotesNotifier(box, ref, deletedNotesService, notesService);
    });

class DeletedNotesNotifier extends StateNotifier<List<DeletedNote>> {
  final Box<DeletedNote> box;
  final DeletedNotesSyncService? _syncService;
  final NoteSyncService? _noteSyncService;
  final Ref _ref;
  late final VoidCallback listener;

  DeletedNotesNotifier(
    this.box,
    this._ref,
    this._syncService,
    this._noteSyncService,
  ) : super(box.values.toList()) {
    purgeExpiredNotes();

    // define the listener once
    listener = () {
      if (mounted) {
        state = box.values.toList();
      }
    };

    // add listener
    box.listenable().addListener(listener);
  }

  @override
  void dispose() {
    // remove listener
    box.listenable().removeListener(listener);
    super.dispose();
  }

  // auto delete notes permanently
  Future<void> purgeExpiredNotes() async {
    await cleanupExpiredNotes();

    state = box.values.toList();
  }

  // add deleted note here
  void addDeletedNote(Note note) {
    final deleted = DeletedNote(
      id: note.id,
      content: note.content,
      contentJson: note.contentJson,
      deletedAt: DateTime.now(),
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );

    box.put(deleted.id, deleted);

    state = box.values.toList();
    // sync deleted note to firestore
    if (_syncService != null) {
      _syncService.syncToFirestore().catchError((error) {});
    }
  }

  //restore deleted note
  void restoreNote(String id) {
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
    box.delete(id);
    state = box.values.toList();
    // add back to active notes collection
    if (_syncService != null && _noteSyncService != null) {
      _syncService
          .restoreFromDeleted(deleted, _noteSyncService)
          .catchError((error) {});
    }
  }

  // permanently delete note from recently deleted
  void permanentlyDeleteNote(String id) {
    box.delete(id);
    state = box.values.toList();

    // permanently remove form fireStore
    if (_syncService != null) {
      _syncService.deletePermanently(id).catchError((error) {});
    }
  }

  Future<void> cleanupExpiredNotes() async {
    final now = DateTime.now();

    final toRemove = box.values
        .where((note) {
          return now.difference(note.deletedAt!).inDays >= 30;
        })
        .map((n) => n.id)
        .toList();

    if (toRemove.isNotEmpty) {
      await box.deleteAll(toRemove);
      state = box.values.toList();

      //delete from firestore
      if (_syncService != null) {
        _syncService.deleteManyPermanently(toRemove).catchError((error) {});
      }
    }
  }
}
