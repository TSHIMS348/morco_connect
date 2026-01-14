// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_kind.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnouncementKindAdapter extends TypeAdapter<AnnouncementKind> {
  @override
  final int typeId = 41;

  @override
  AnnouncementKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AnnouncementKind.announcement;
      case 1:
        return AnnouncementKind.story;
      default:
        return AnnouncementKind.announcement;
    }
  }

  @override
  void write(BinaryWriter writer, AnnouncementKind obj) {
    switch (obj) {
      case AnnouncementKind.announcement:
        writer.writeByte(0);
        break;
      case AnnouncementKind.story:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementKindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
