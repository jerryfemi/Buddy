import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../firebase/sync_service/global_sync_manager.dart';
import '../models/note_model.dart';
import '../models/deleted_notes_model.dart';
import '../models/calendar_event_model.dart';
import '../models/previous_events_model.dart';
import '../models/task_model.dart';
import 'auth_provider.dart';

final globalSyncManagerProvider = Provider<GlobalSyncManager?>((ref) {
  // Watch the auth state
  final user = ref.watch(authNotifierProvider);

  // If no user, no sync manager
  if (user == null) return null;

  // Return a new manager for the logged-in user
  return GlobalSyncManager(
    userId: user.uid,
    noteBox: Hive.box<Note>('notesBox'),
    deletedNoteBox: Hive.box<DeletedNote>('deletedNotesBox'),
    eventBox: Hive.box<CalendarEvent>('eventsBox'),
    previousEventBox: Hive.box<PreviousEvents>('previousEventsBox'),
    taskBox: Hive.box<Task>('tasksBox'),
  );
});
