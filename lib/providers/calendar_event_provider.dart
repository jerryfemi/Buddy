import 'dart:ui';

import 'package:buddy/firebase/sync_service/calendar_event_sync_service.dart';
import 'package:buddy/firebase/sync_service/previous_events_sync_srevice.dart';
import 'package:buddy/providers/auth_provider.dart';
import 'package:buddy/providers/previous_events_provider.dart';
import 'package:buddy/services/events_notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:uuid/uuid.dart';

import '../models/calendar_event_model.dart';

// Access Hive box
final eventsBoxProvider = Provider<Box<CalendarEvent>>(
  (ref) => Hive.box<CalendarEvent>('eventsBox'),
);

// calendarEvents syncService provider
final calendarEventsSyncServiceProvider = Provider<CalendarEventSyncService?>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  final box = ref.watch(eventsBoxProvider);

  if (user == null) return null;

  return CalendarEventSyncService(userId: user.uid, eventBox: box);
});

// All events from box (raw + rollover applied)
final eventsProvider =
    StateNotifierProvider<CalendarEventNotifier, List<CalendarEvent>>((ref) {
      final box = ref.watch(eventsBoxProvider);
      final eventsService = ref.watch(calendarEventsSyncServiceProvider);
      final preEventsService = ref.watch(previousEventsSyncServiceProvider);
      return CalendarEventNotifier(box, ref, eventsService, preEventsService);
    });

// Notifier
class CalendarEventNotifier extends StateNotifier<List<CalendarEvent>> {
  final Box<CalendarEvent> _box;
  final CalendarEventSyncService? _syncService;
  final PreviousEventSyncService? _eventSyncService;
  final Ref _ref;
  late final VoidCallback listener;

  CalendarEventNotifier(
    this._box,
    this._ref,
    this._syncService,
    this._eventSyncService,
  ) : super([]) {
    _refreshState();
    loadEvents();

    // define the listener
    listener = () {
      if (mounted) {
        _refreshState();
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

  final _eventsNotifs = EventsNotificationsRepository();

  // initialize tasks
  Future<void> loadEvents() async {
    final initial = _box.values.toList();
    if (mounted) state = initial;
  }

  //  Add new event
  void addEvent({
    required String title,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? description,
    bool isAllDay = false,
    List<int> reminders = const [],
    String repeatRule = 'never',
  }) {
    final newEvent = CalendarEvent(
      id: const Uuid().v4(),
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isAllDay: isAllDay,
      reminders: reminders,
      repeatRule: repeatRule,
    );

    _box.put(newEvent.id, newEvent);

    // schedule notifications
    _eventsNotifs.schedulePreEventReminders(newEvent);
    _eventsNotifs.scheduleEventReminder(newEvent);

    // apply rollover immediately
    _refreshState();
    // sync events to fireStore
    if (_syncService != null) {
      _syncService.syncToFirestore(newEvent).catchError((error) {});
    }
  }

  //  Delete event → moves to "previous events"
  void deleteEvent(String id) {
    final event = _box.get(id);
    if (event == null) return;

    _ref.read(previousEventsProvider.notifier).addPreviousEvents(event);
    _box.delete(id);

    _refreshState();
    // delete notifications
    _eventsNotifs.cancelEventReminder(event);

    // delete event from fireStore
    if (_syncService != null && _eventSyncService != null) {
      final previousService = _eventSyncService;
      _syncService
          .moveToPreviousEvents(event, previousService)
          .catchError((error) {});
    }
  }

  // apply rollOver across all events
  void _refreshState() {
    final updated = <CalendarEvent>[];
    for (final event in _box.values) {
      final rolled = _rolloverIfExpired(event);
      if (rolled != null) updated.add(rolled);
    }
    state = updated;
  }

  void cleanupExpiredEvents() {
    final now = DateTime.now();
    final expired = _box.values.where(
      (event) => event.endDateTime.isBefore(now),
    );
    for (final event in expired) {
      _ref.read(previousEventsProvider.notifier).addPreviousEvents(event);
      _box.delete(event.id);

      // remove from firestore collection
      if (_syncService != null && _eventSyncService != null) {
        final previousService = _eventSyncService;
        _syncService
            .moveToPreviousEvents(event, previousService)
            .catchError((error) {});
      }
    }
  }

  //  Rollover events when repeat  expired
  CalendarEvent? _rolloverIfExpired(CalendarEvent event) {
    final now = DateTime.now();

    // If still active → keep
    if (event.endDateTime.isAfter(now)) return event;

    // If no repeat → archive
    if (event.repeatRule == 'never') {
      _ref.read(previousEventsProvider.notifier).addPreviousEvents(event);
      _box.delete(event.id);
      return null;
    }

    // Otherwise compute next occurrence
    DateTime nextStart = event.startDateTime;
    DateTime nextEnd = event.endDateTime;

    while (!nextEnd.isAfter(now)) {
      nextStart = _getNextOccurrence(event.startDateTime, event.repeatRule);
      nextEnd = _getNextOccurrence(event.endDateTime, event.repeatRule);
    }

    // Move old occurrence to previous
    _ref.read(previousEventsProvider.notifier).addPreviousEvents(event);

    if (_syncService != null && _eventSyncService != null) {
      final previousService = _eventSyncService;
      _syncService
          .moveToPreviousEvents(event, previousService)
          .catchError((error) {});
    }

    final updated = event.copyWith(
      startDateTime: nextStart,
      endDateTime: nextEnd,
    );

    _box.put(event.id, updated);

    // schedule new notifications for rolled over events
    _eventsNotifs.schedulePreEventReminders(updated);
    _eventsNotifs.scheduleEventReminder(updated);

    return updated;
  }

  //  calculate next occurrence
  DateTime _getNextOccurrence(DateTime from, String rule) {
    switch (rule) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'monthly':
        final nextMonth = DateTime(from.year, from.month + 1, 1);
        final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final safeDay = from.day > lastDay ? lastDay : from.day;
        return DateTime(
          nextMonth.year,
          nextMonth.month,
          safeDay,
          from.hour,
          from.minute,
        );
      case 'yearly':
        return DateTime(
          from.year + 1,
          from.month,
          from.day,
          from.hour,
          from.minute,
        );
      default:
        return from;
    }
  }
}

// Repeat handling for calendar UI

// Expand an event into all its occurrences within a given month
List<DateTime> getOccurrencesInMonth(CalendarEvent event, DateTime monthStart) {
  final List<DateTime> occurrences = [];
  final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

  DateTime occ =
      event.startDateTime; // ← now always the rolled-forward one in Hive/state

  while (occ.isBefore(monthEnd.add(const Duration(days: 1)))) {
    if (occ.isAfter(monthStart.subtract(const Duration(days: 1))) &&
        occ.isBefore(monthEnd.add(const Duration(days: 1)))) {
      occurrences.add(DateTime(occ.year, occ.month, occ.day));
    }

    // advance by repeat rule
    switch (event.repeatRule) {
      case 'daily':
        occ = occ.add(const Duration(days: 1));
        break;
      case 'weekly':
        occ = occ.add(const Duration(days: 7));
        break;
      case 'monthly':
        final nextMonth = DateTime(occ.year, occ.month + 1, 1);
        final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final safeDay = occ.day > lastDay ? lastDay : occ.day;
        occ = DateTime(
          nextMonth.year,
          nextMonth.month,
          safeDay,
          occ.hour,
          occ.minute,
        );
        break;
      case 'yearly':
        occ = DateTime(occ.year + 1, occ.month, occ.day, occ.hour, occ.minute);
        break;
      default:
        occ = monthEnd.add(const Duration(days: 2)); // exit loop
    }
  }

  return occurrences;
}

// Map of dates → events (used for TableCalendar highlights)
final eventsOccurrencesProvider =
    Provider.family<Map<DateTime, List<CalendarEvent>>, DateTime>((ref, month) {
      final events = ref.watch(eventsProvider);
      final Map<DateTime, List<CalendarEvent>> occurrences = {};

      for (final event in events) {
        final occs = getOccurrencesInMonth(event, month);
        for (final date in occs) {
          final key = DateTime(date.year, date.month, date.day);
          occurrences.putIfAbsent(key, () => []).add(event);
        }
      }
      return occurrences;
    });

// Events for a specific day (used in event list / sliver)
final eventsForDateProvider = Provider.family<List<CalendarEvent>, DateTime>((
  ref,
  day,
) {
  final monthStart = DateTime(day.year, day.month, 1);
  final occs = ref.watch(eventsOccurrencesProvider(monthStart));
  final key = DateTime(day.year, day.month, day.day);

  final events = occs[key] ?? [];

  // clone with clicked day's date
  return events.map((e) {
    if (e.repeatRule != 'never') {
      return e.copyWith(
        startDateTime: DateTime(
          day.year,
          day.month,
          day.day,
          e.startDateTime.hour,
          e.startDateTime.minute,
        ),
      );
    }
    return e;
  }).toList();
});

// Upcoming events (sorted, today onwards)
final upcomingEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final events = ref.watch(eventsProvider);
  final now = DateTime.now();

  final upcoming =
      events
          .where(
            (e) =>
                e.startDateTime.isAfter(now) ||
                _isSameDay(e.startDateTime, now),
          )
          .toList()
        ..sort((a, b) {
          final aReminder = a.reminders.isNotEmpty
              ? a.reminders.reduce(
                  (x, y) => x < y ? x : y,
                ) // pick smallest reminder
              : 0;

          final bReminder = b.reminders.isNotEmpty
              ? b.reminders.reduce((x, y) => x < y ? x : y)
              : 0;

          final at = a.startDateTime.subtract(Duration(minutes: aReminder));
          final bt = b.startDateTime.subtract(Duration(minutes: bReminder));

          return at.compareTo(bt);
        });

  return upcoming;
});

// Helpers
bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// getters
Provider<List<CalendarEvent>> get upComingEvents => upcomingEventsProvider;
