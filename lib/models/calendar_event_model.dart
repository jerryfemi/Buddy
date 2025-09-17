import 'package:hive/hive.dart';

part 'calendar_event_model.g.dart';

@HiveType(typeId: 2)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime startDateTime;

  @HiveField(3)
  final bool isAllDay;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final List<int> reminders;

  @HiveField(6)
  final DateTime endDateTime;

  @HiveField(7)
  String repeatRule;

  CalendarEvent({
    required this.id,
    required this.startDateTime,
    this.isAllDay = false,
    this.description,
    required this.endDateTime,
    this.reminders = const [],
    this.repeatRule = 'never',
    required this.title,
  });

  // copy with
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isAllDay,
    List<int>? reminders,
    String? repeatRule,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      title: title ?? this.title,
      description: description ?? this.description,
      reminders: reminders ?? this.reminders,
      isAllDay: isAllDay ?? this.isAllDay,
      repeatRule: repeatRule ?? this.repeatRule,
    );
  }
}
