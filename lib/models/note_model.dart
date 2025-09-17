import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  late final String content;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  late final DateTime updatedAt;

  @HiveField(4)
  late final String contentJson;

  Note({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.contentJson,
    required this.updatedAt,
  });

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

  Note copyWith({
    String? id,
    String? content,
    String? contentJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      contentJson: contentJson ?? this.contentJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
