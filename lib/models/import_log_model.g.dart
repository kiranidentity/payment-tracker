// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImportLogModelAdapter extends TypeAdapter<ImportLogModel> {
  @override
  final int typeId = 2;

  @override
  ImportLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImportLogModel(
      fileName: fields[0] as String,
      timestamp: fields[1] as DateTime,
      transactionCount: fields[2] as int,
      status: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ImportLogModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.fileName)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.transactionCount)
      ..writeByte(3)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
