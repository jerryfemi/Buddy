import 'package:buddy/models/previous_events_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreviousEventFirestore {
  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;

  PreviousEventFirestore({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
  });

  factory PreviousEventFirestore.fromHive(PreviousEvents event) {
    return PreviousEventFirestore(
      id: event.id,
      title: event.title,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      description: event.description,
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
    };
  }

  factory PreviousEventFirestore.fromMap(String id, Map<String, dynamic> map) {
    return PreviousEventFirestore(
      id: id,
      title: map['title'] ?? '',
      startDateTime: (map['startDateTime'] as Timestamp).toDate(),
      endDateTime: (map['endDateTime'] as Timestamp).toDate(),
      description: map['description'],
    );
  }
}
