// lib/models/deleted_note.dart
import 'package:hive/hive.dart';

part 'deleted_notes_model.g.dart';

@HiveType(typeId: 4) //
class DeletedNote {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final String contentJson; // Full Quill JSON string

  @HiveField(3)
  final DateTime deletedAt; // Timestamp of deletion
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final DateTime updatedAt;

  // clean content and split into non empty lines
  List<String> _nonEmptyLines() {
    return content
        .replaceAll(RegExp(r'\n+$'), '')
        .trim()
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }

  // stored title
  String get title {
    final lines = _nonEmptyLines();

    return lines.isNotEmpty ? lines.first : 'Untitled';
  }

  // stored subtitle
  String get subtitle {
    final lines = _nonEmptyLines();
    return lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
  }

  DeletedNote({
    required this.id,
    required this.content,
    required this.contentJson,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}
