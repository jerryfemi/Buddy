import 'package:buddy/models/deleted_notes_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeletedNoteFirestore {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime deletedAt;
  final String contentJson;

  DeletedNoteFirestore({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.contentJson,
  });

  // From Hive Note (mark deletedAt as now)
  factory DeletedNoteFirestore.fromHive(DeletedNote note) {
    return DeletedNoteFirestore(
      id: note.id,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      deletedAt: note.deletedAt,
      contentJson: note.contentJson,
    );
  }

  // Back to Hive Note Not restoring)
  DeletedNote toHive() {
    return DeletedNote(
      id: id,
      content: content,
      contentJson: contentJson,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // To Firestore Map using Timestamp
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deletedAt': Timestamp.fromDate(deletedAt),
      'contentJson': contentJson,
    };
  }

  // From Firestore Map
  factory DeletedNoteFirestore.fromMap(String id, Map<String, dynamic> map) {
    return DeletedNoteFirestore(
      id: id,
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      deletedAt: (map['deletedAt'] as Timestamp).toDate(),
      contentJson: map['contentJson'],
    );
  }
}
