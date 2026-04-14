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
  final DateTime? updatedAt;

  CalendarEventFirestore({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.isAllDay,
    this.description,
    required this.reminders,
    required this.endDateTime,
    this.repeatRule = 'never',
    this.updatedAt,
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
      updatedAt: DateTime.now(),
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
      'updatedAt': updatedAt,
    };
  }

  // From Firestore
  factory CalendarEventFirestore.fromMap(String id, Map<String, dynamic> map) {
    final startDateTime = _readDate(
      map['startDateTime'],
      fallback: DateTime.now(),
    );
    final endDateTime = _readDate(map['endDateTime'], fallback: startDateTime);

    return CalendarEventFirestore(
      id: id,
      title: map['title'] ?? '',
      startDateTime: startDateTime,
      isAllDay: map['isAllDay'] ?? false,
      description: map['description'],
      reminders: List<int>.from(map['reminders'] ?? []),
      endDateTime: endDateTime,
      repeatRule: map['repeatRule'] ?? 'never',
      updatedAt: _readNullableDate(map['updatedAt']),
    );
  }

  static DateTime _readDate(dynamic value, {required DateTime fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return fallback;
  }

  static DateTime? _readNullableDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
