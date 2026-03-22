// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TournamentModelAdapter extends TypeAdapter<TournamentModel> {
  @override
  final int typeId = 1;

  @override
  TournamentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TournamentModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      playerNames: (fields[2] as List).cast<String>(),
      groupAssignments: (fields[3] as List).cast<String>(),
      status: fields[4] as String,
      type: fields[5] as String,
      championName: fields[6] as String?,
      createdAt: fields[7] as DateTime?,
      gameMode: fields[8] as String,
      turnTimerSeconds: fields[9] as int,
      customRules: fields[10] as CustomRules,
    );
  }

  @override
  void write(BinaryWriter writer, TournamentModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.playerNames)
      ..writeByte(3)
      ..write(obj.groupAssignments)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.championName)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.gameMode)
      ..writeByte(9)
      ..write(obj.turnTimerSeconds)
      ..writeByte(10)
      ..write(obj.customRules);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
