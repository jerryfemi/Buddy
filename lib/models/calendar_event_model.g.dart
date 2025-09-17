// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalendarEventAdapter extends TypeAdapter<CalendarEvent> {
  @override
  final int typeId = 2;

  @override
  CalendarEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarEvent(
      id: fields[0] as String,
      startDateTime: fields[2] as DateTime,
      isAllDay: fields[3] as bool,
      description: fields[4] as String?,
      endDateTime: fields[6] as DateTime,
      reminders: (fields[5] as List).cast<int>(),
      repeatRule: fields[7] as String,
      title: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarEvent obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.startDateTime)
      ..writeByte(3)
      ..write(obj.isAllDay)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.reminders)
      ..writeByte(6)
      ..write(obj.endDateTime)
      ..writeByte(7)
      ..write(obj.repeatRule);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
