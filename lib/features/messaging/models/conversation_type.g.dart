// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationTypeAdapter extends TypeAdapter<ConversationType> {
  @override
  final int typeId = 12;

  @override
  ConversationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ConversationType.global;
      case 1:
        return ConversationType.project;
      case 2:
        return ConversationType.site;
      case 3:
        return ConversationType.city;
      case 4:
        return ConversationType.direct;
      case 5:
        return ConversationType.announcement;
      default:
        return ConversationType.global;
    }
  }

  @override
  void write(BinaryWriter writer, ConversationType obj) {
    switch (obj) {
      case ConversationType.global:
        writer.writeByte(0);
        break;
      case ConversationType.project:
        writer.writeByte(1);
        break;
      case ConversationType.site:
        writer.writeByte(2);
        break;
      case ConversationType.city:
        writer.writeByte(3);
        break;
      case ConversationType.direct:
        writer.writeByte(4);
        break;
      case ConversationType.announcement:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
