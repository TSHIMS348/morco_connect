// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnouncementTypeAdapter extends TypeAdapter<AnnouncementType> {
  @override
  final int typeId = 30;

  @override
  AnnouncementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AnnouncementType.text;
      case 1:
        return AnnouncementType.image;
      case 2:
        return AnnouncementType.video;
      case 3:
        return AnnouncementType.document;
      case 4:
        return AnnouncementType.letter;
      default:
        return AnnouncementType.text;
    }
  }

  @override
  void write(BinaryWriter writer, AnnouncementType obj) {
    switch (obj) {
      case AnnouncementType.text:
        writer.writeByte(0);
        break;
      case AnnouncementType.image:
        writer.writeByte(1);
        break;
      case AnnouncementType.video:
        writer.writeByte(2);
        break;
      case AnnouncementType.document:
        writer.writeByte(3);
        break;
      case AnnouncementType.letter:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
