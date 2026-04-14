import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/note_model.dart';

class NoteFirestore {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? contentJson;

  NoteFirestore({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.contentJson,
  });

  // From Hive to firestore
  factory NoteFirestore.fromHive(Note note) {
    return NoteFirestore(
      id: note.id,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      contentJson: note.contentJson,
    );
  }

  // form firestore To Hive
  Note toHive() {
    return Note(
      id: id,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      contentJson: contentJson ?? '',
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'contentJson': contentJson,
    };
  }

  // From Firestore
  factory NoteFirestore.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = _readDate(map['createdAt'], fallback: DateTime.now());
    final updatedAt = _readDate(map['updatedAt'], fallback: createdAt);

    return NoteFirestore(
      id: id,
      content: map['content'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      contentJson: map['contentJson'],
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
}
