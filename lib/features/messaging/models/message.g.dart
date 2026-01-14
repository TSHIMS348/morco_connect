// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 2;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      id: fields[0] as String,
      conversationId: fields[1] as String,
      senderMatricule: fields[2] as String,
      senderRole: fields[3] as UserRole,
      content: fields[4] as String?,
      attachments: (fields[5] as List).cast<Attachment>(),
      sentAt: fields[6] as DateTime,
      status: fields[7] as MessageStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.senderMatricule)
      ..writeByte(3)
      ..write(obj.senderRole)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.attachments)
      ..writeByte(6)
      ..write(obj.sentAt)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
