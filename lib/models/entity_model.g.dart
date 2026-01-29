// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EntityModelAdapter extends TypeAdapter<EntityModel> {
  @override
  final int typeId = 1;

  @override
  EntityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EntityModel(
      id: fields[0] as String,
      name: fields[1] as String,
      monthlyLimit: fields[2] as double?,
      aliases: (fields[3] as List).cast<String>(),
      amountAliases: (fields[4] as List).cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, EntityModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.monthlyLimit)
      ..writeByte(3)
      ..write(obj.aliases)
      ..writeByte(4)
      ..write(obj.amountAliases);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
