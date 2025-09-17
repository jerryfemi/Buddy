import 'package:buddy/models/calendar_event_model.dart';
import 'package:buddy/models/previous_events_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';

final previousEventsBoxProvider = Provider<Box<PreviousEvents>>(
  (ref) => Hive.box('previousEventsBox'),
);

final previousEventsProvider =
    StateNotifierProvider<PreviousEventsNotifier, List<PreviousEvents>>((ref) {
      final box = ref.watch(previousEventsBoxProvider);
      return PreviousEventsNotifier(box);
    });

class PreviousEventsNotifier extends StateNotifier<List<PreviousEvents>> {
  final Box<PreviousEvents> _box;

  PreviousEventsNotifier(this._box) : super(_box.values.toList());

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
  }

  // permanently delete events
  Future<void> permanentlyDeleteEvents(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
  }

  // clear all
  Future<void> clearPreviousEvents() async {
    await _box.clear();
    state = _box.values.toList();
  }
}
