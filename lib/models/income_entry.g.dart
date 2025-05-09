// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IncomeEntryAdapter extends TypeAdapter<IncomeEntry> {
  @override
  final int typeId = 1;

  @override
  IncomeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IncomeEntry(
      item: fields[0] as String,
      category: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      person: fields[4] as String,
      account: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, IncomeEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.item)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.person)
      ..writeByte(5)
      ..write(obj.account);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
