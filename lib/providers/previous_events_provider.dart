import 'dart:ui';

import 'package:buddy/firebase/sync_service/previous_events_sync_srevice.dart';
import 'package:buddy/models/calendar_event_model.dart';
import 'package:buddy/models/previous_events_model.dart';
import 'package:buddy/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/adapters.dart';

final previousEventsBoxProvider = Provider<Box<PreviousEvents>>(
  (ref) => Hive.box('previousEventsBox'),
);

// previous events sync service provider
final previousEventsSyncServiceProvider = Provider<PreviousEventSyncService?>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  final box = ref.watch(previousEventsBoxProvider);

  if (user == null) return null;
  return PreviousEventSyncService(userId: user.uid, previousEventBox: box);
});

final previousEventsProvider =
    StateNotifierProvider<PreviousEventsNotifier, List<PreviousEvents>>((ref) {
      final box = ref.watch(previousEventsBoxProvider);
      final prevEventsService = ref.watch(previousEventsSyncServiceProvider);
      return PreviousEventsNotifier(box, prevEventsService);
    });

class PreviousEventsNotifier extends StateNotifier<List<PreviousEvents>> {
  final Box<PreviousEvents> _box;
  final PreviousEventSyncService? _syncService;
  late final VoidCallback listener;

  PreviousEventsNotifier(this._box, this._syncService) : super([]) {
    loadPreEvents();

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

  // load previousEe=vents

  // initialize tasks
  Future<void> loadPreEvents() async {
    final initial = _box.values.toList();
    if (mounted) state = initial;
  }

  // addPreviousEvents
  Future<void> addPreviousEvents(CalendarEvent event) async {
    final prev = PreviousEvents(
      id: event.id,
      title: event.title,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      description: event.description,
    );
    await _box.put(prev.id, prev);
    state = _box.values.toList();

    // sync to fire store
    if (_syncService != null) {
      await _syncService.syncToFirestore(prev);
    }
  }

  // permanently delete events
  Future<void> permanentlyDeleteEvents(String id) async {
    await _box.delete(id);
    state = _box.values.toList();

    // delete from fire store (permanently)
    if (_syncService != null) {
      await _syncService.deleteFromFirestorePermanently(id);
    }
  }

  // clear all
  Future<void> clearPreviousEvents() async {
    final preEvents = _box.values.toList();

    // clear hive box
    await _box.clear();
    state = [];

    // delete all from fireStore
    if (_syncService != null) {

      await Future.wait(
        preEvents.map((prev) async {
          await _syncService.deleteFromFirestorePermanently(prev.id);
        }),
      );
    }
  }
}
