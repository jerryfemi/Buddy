// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'previous_events_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PreviousEventsAdapter extends TypeAdapter<PreviousEvents> {
  @override
  final int typeId = 5;

  @override
  PreviousEvents read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PreviousEvents(
      id: fields[0] as String,
      title: fields[1] as String,
      startDateTime: fields[3] as DateTime,
      endDateTime: fields[4] as DateTime,
      description: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PreviousEvents obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.startDateTime)
      ..writeByte(4)
      ..write(obj.endDateTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviousEventsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
