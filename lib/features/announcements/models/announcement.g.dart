// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnouncementAdapter extends TypeAdapter<Announcement> {
  @override
  final int typeId = 34;

  @override
  Announcement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Announcement(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String?,
      type: fields[3] as AnnouncementType,
      priority: fields[4] as AnnouncementPriority,
      mediaPath: fields[5] as String?,
      authorMatricule: fields[6] as String,
      authorRole: fields[7] as UserRole,
      createdAt: fields[8] as DateTime,
      targets: (fields[9] as List).cast<AnnouncementTarget>(),
      readBy: (fields[10] as List).cast<String>(),
      status: fields[50] as AnnouncementStatus,
      submittedAt: fields[51] as DateTime?,
      submittedByMatricule: fields[52] as String?,
      validatedAt: fields[53] as DateTime?,
      validatedByMatricule: fields[54] as String?,
      scheduledAt: fields[55] as DateTime?,
      rejectReason: fields[56] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Announcement obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.mediaPath)
      ..writeByte(6)
      ..write(obj.authorMatricule)
      ..writeByte(7)
      ..write(obj.authorRole)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.targets)
      ..writeByte(10)
      ..write(obj.readBy)
      ..writeByte(50)
      ..write(obj.status)
      ..writeByte(51)
      ..write(obj.submittedAt)
      ..writeByte(52)
      ..write(obj.submittedByMatricule)
      ..writeByte(53)
      ..write(obj.validatedAt)
      ..writeByte(54)
      ..write(obj.validatedByMatricule)
      ..writeByte(55)
      ..write(obj.scheduledAt)
      ..writeByte(56)
      ..write(obj.rejectReason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
