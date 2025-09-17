import 'package:hive/hive.dart';

part 'previous_events_model.g.dart';

@HiveType(typeId: 5)
class PreviousEvents extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime startDateTime;

  @HiveField(4)
  DateTime endDateTime;

  PreviousEvents({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
  });
}
