// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_priority.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnouncementPriorityAdapter extends TypeAdapter<AnnouncementPriority> {
  @override
  final int typeId = 31;

  @override
  AnnouncementPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AnnouncementPriority.normal;
      case 1:
        return AnnouncementPriority.important;
      case 2:
        return AnnouncementPriority.critical;
      default:
        return AnnouncementPriority.normal;
    }
  }

  @override
  void write(BinaryWriter writer, AnnouncementPriority obj) {
    switch (obj) {
      case AnnouncementPriority.normal:
        writer.writeByte(0);
        break;
      case AnnouncementPriority.important:
        writer.writeByte(1);
        break;
      case AnnouncementPriority.critical:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
