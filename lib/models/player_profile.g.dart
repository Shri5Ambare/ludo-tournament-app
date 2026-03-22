// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerProfileAdapter extends TypeAdapter<PlayerProfile> {
  @override
  final int typeId = 0;

  @override
  PlayerProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerProfile(
      id: fields[0] as String?,
      name: fields[1] as String,
      avatarEmoji: fields[2] as String,
      wins: fields[3] as int,
      losses: fields[4] as int,
      coins: fields[5] as int,
      xp: fields[6] as int,
      level: fields[7] as int,
      winStreak: fields[8] as int,
      bestRank: fields[9] as int,
      gamesPlayed: fields[10] as int,
      tournamentsWon: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerProfile obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatarEmoji)
      ..writeByte(3)
      ..write(obj.wins)
      ..writeByte(4)
      ..write(obj.losses)
      ..writeByte(5)
      ..write(obj.coins)
      ..writeByte(6)
      ..write(obj.xp)
      ..writeByte(7)
      ..write(obj.level)
      ..writeByte(8)
      ..write(obj.winStreak)
      ..writeByte(9)
      ..write(obj.bestRank)
      ..writeByte(10)
      ..write(obj.gamesPlayed)
      ..writeByte(11)
      ..write(obj.tournamentsWon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
