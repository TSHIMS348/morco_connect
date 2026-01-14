// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_target.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnouncementTargetAdapter extends TypeAdapter<AnnouncementTarget> {
  @override
  final int typeId = 33;

  @override
  AnnouncementTarget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnouncementTarget(
      type: fields[0] as AnnouncementTargetType,
      refId: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AnnouncementTarget obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.refId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementTargetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
