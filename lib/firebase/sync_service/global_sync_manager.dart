import 'package:buddy/firebase/sync_service/previous_events_sync_srevice.dart';
import 'package:buddy/firebase/sync_service/tasks_sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'dart:async';

import '../../models/calendar_event_model.dart';
import '../../models/deleted_notes_model.dart';
import '../../models/note_model.dart';
import '../../models/previous_events_model.dart';
import '../../models/task_model.dart';
import 'calendar_event_sync_service.dart';
import 'deleted_notes_sync_service.dart';
import 'notes_sync_service.dart';

class GlobalSyncManager {
  final String userId;

  late final NoteSyncService _noteSync;
  late final DeletedNotesSyncService _deletedNotesSync;
  late final CalendarEventSyncService _calendarEventSync;
  late final PreviousEventSyncService _previousEventSync;
  late final TaskSyncService _taskSyncService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void>? _activeSync;

  GlobalSyncManager({
    required this.userId,
    required Box<Note> noteBox,
    required Box<DeletedNote> deletedNoteBox,
    required Box<CalendarEvent> eventBox,
    required Box<PreviousEvents> previousEventBox,
    required Box<Task> taskBox,
  }) {
    _noteSync = NoteSyncService(userId: userId, noteBox: noteBox);
    _deletedNotesSync = DeletedNotesSyncService(
      userId: userId,
      deletedNoteBox: deletedNoteBox,
    );
    _calendarEventSync = CalendarEventSyncService(
      userId: userId,
      eventBox: eventBox,
    );
    _previousEventSync = PreviousEventSyncService(
      userId: userId,
      previousEventBox: previousEventBox,
    );
    _taskSyncService = TaskSyncService(userId: userId, taskBox: taskBox);
  }


  void listenForConnectivityAndSync() {
    if (_connectivitySubscription != null) return;

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      if (!results.contains(ConnectivityResult.none)) {
        await syncAll();
      }
    });
  }

  Future<void> stopConnectivityListener() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  // Sync ALL
  Future<void> syncAll() async {
    if (_activeSync != null) {
      await _activeSync;
      return;
    }

    _activeSync = Future.wait([
      _noteSync.syncAll(),
      _deletedNotesSync.fullSync(),
      _calendarEventSync.syncAll(),
      _previousEventSync.syncAll(),
      _taskSyncService.syncAll(),
    ]).then((_) {});

    try {
      await _activeSync;
    } finally {
      _activeSync = null;
    }
  }

  Future<void> dispose() async {
    await stopConnectivityListener();
  }
}
