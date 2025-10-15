// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_notes_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeletedNoteAdapter extends TypeAdapter<DeletedNote> {
  @override
  final int typeId = 4;

  @override
  DeletedNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeletedNote(
      id: fields[0] as String,
      content: fields[1] as String,
      contentJson: fields[2] as String,
      deletedAt: fields[3] as DateTime?,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DeletedNote obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.contentJson)
      ..writeByte(3)
      ..write(obj.deletedAt)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletedNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
