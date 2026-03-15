// lib/models/player_profile.g.dart
// GENERATED CODE - Manual stub for Hive adapter

part of 'player_profile.dart';

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
      avatarEmoji: fields[2] as String? ?? '🎮',
      wins: fields[3] as int? ?? 0,
      losses: fields[4] as int? ?? 0,
      coins: fields[5] as int? ?? 500,
      xp: fields[6] as int? ?? 0,
      level: fields[7] as int? ?? 1,
      winStreak: fields[8] as int? ?? 0,
      bestRank: fields[9] as int? ?? 0,
      gamesPlayed: fields[10] as int? ?? 0,
      tournamentsWon: fields[11] as int? ?? 0,
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
