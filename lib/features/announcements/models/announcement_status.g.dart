// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnouncementStatusAdapter extends TypeAdapter<AnnouncementStatus> {
  @override
  final int typeId = 31;

  @override
  AnnouncementStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AnnouncementStatus.draft;
      case 1:
        return AnnouncementStatus.pendingValidation;
      case 2:
        return AnnouncementStatus.scheduled;
      case 3:
        return AnnouncementStatus.published;
      case 4:
        return AnnouncementStatus.rejected;
      default:
        return AnnouncementStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, AnnouncementStatus obj) {
    switch (obj) {
      case AnnouncementStatus.draft:
        writer.writeByte(0);
        break;
      case AnnouncementStatus.pendingValidation:
        writer.writeByte(1);
        break;
      case AnnouncementStatus.scheduled:
        writer.writeByte(2);
        break;
      case AnnouncementStatus.published:
        writer.writeByte(3);
        break;
      case AnnouncementStatus.rejected:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
