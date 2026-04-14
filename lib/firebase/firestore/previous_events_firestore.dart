import 'package:buddy/models/previous_events_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreviousEventFirestore {
  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;
  final DateTime? updatedAt;

  PreviousEventFirestore({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
    this.updatedAt,
  });

  factory PreviousEventFirestore.fromHive(PreviousEvents event) {
    return PreviousEventFirestore(
      id: event.id,
      title: event.title,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      description: event.description,
      updatedAt: DateTime.now(),
    );
  }

  // to hive
  PreviousEvents toHive() {
    return PreviousEvents(
      id: id,
      title: title,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      description: description,
    );
  }

  // to Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'description': description,
      'updatedAt': updatedAt,
    };
  }

  factory PreviousEventFirestore.fromMap(String id, Map<String, dynamic> map) {
    final startDateTime = _readDate(
      map['startDateTime'],
      fallback: DateTime.now(),
    );
    final endDateTime = _readDate(map['endDateTime'], fallback: startDateTime);

    return PreviousEventFirestore(
      id: id,
      title: map['title'] ?? '',
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      description: map['description'],
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
