import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/calendar_event_model.dart';
class CalendarEventFirestore {
  final String id;
  final String title;
  final DateTime startDateTime;
  final bool isAllDay;
  final String? description;
  final List<int> reminders;
  final DateTime endDateTime;
  final String repeatRule;

  CalendarEventFirestore({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.isAllDay,
    this.description,
    required this.reminders,
    required this.endDateTime,
    this.repeatRule = 'never',
  });

  // From Hive
  factory CalendarEventFirestore.fromHive(CalendarEvent event) {
    return CalendarEventFirestore(
      id: event.id,
      title: event.title,
      startDateTime: event.startDateTime,
      isAllDay: event.isAllDay,
      description: event.description,
      reminders: event.reminders,
      endDateTime: event.endDateTime,
      repeatRule: event.repeatRule,
    );
  }

  // To Hive
  CalendarEvent toHive() {
    return CalendarEvent(
      id: id,
      title: title,
      startDateTime: startDateTime,
      isAllDay: isAllDay,
      description: description,
      reminders: reminders,
      endDateTime: endDateTime,
      repeatRule: repeatRule,
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startDateTime': startDateTime,
      'isAllDay': isAllDay,
      'description': description,
      'reminders': reminders,
      'endDateTime': endDateTime,
      'repeatRule': repeatRule,
    };
  }

  // From Firestore
  factory CalendarEventFirestore.fromMap(String id, Map<String, dynamic> map) {
    return CalendarEventFirestore(
      id: id,
      title: map['title'] ?? '',
      startDateTime: (map['startDateTime'] as Timestamp).toDate(),
      isAllDay: map['isAllDay'] ?? false,
      description: map['description'],
      reminders: List<int>.from(map['reminders'] ?? []),
      endDateTime: (map['endDateTime'] as Timestamp).toDate(),
      repeatRule: map['repeatRule'],
    );
  }
}