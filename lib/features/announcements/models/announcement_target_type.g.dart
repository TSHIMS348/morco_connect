// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_target_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnouncementTargetTypeAdapter
    extends TypeAdapter<AnnouncementTargetType> {
  @override
  final int typeId = 32;

  @override
  AnnouncementTargetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AnnouncementTargetType.all;
      case 1:
        return AnnouncementTargetType.site;
      case 2:
        return AnnouncementTargetType.city;
      case 3:
        return AnnouncementTargetType.project;
      default:
        return AnnouncementTargetType.all;
    }
  }

  @override
  void write(BinaryWriter writer, AnnouncementTargetType obj) {
    switch (obj) {
      case AnnouncementTargetType.all:
        writer.writeByte(0);
        break;
      case AnnouncementTargetType.site:
        writer.writeByte(1);
        break;
      case AnnouncementTargetType.city:
        writer.writeByte(2);
        break;
      case AnnouncementTargetType.project:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementTargetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
