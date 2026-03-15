// lib/models/player_profile.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'player_profile.g.dart';

@HiveType(typeId: 0)
class PlayerProfile extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String avatarEmoji;

  @HiveField(3)
  late int wins;

  @HiveField(4)
  late int losses;

  @HiveField(5)
  late int coins;

  @HiveField(6)
  late int xp;

  @HiveField(7)
  late int level;

  @HiveField(8)
  late int winStreak;

  @HiveField(9)
  late int bestRank;

  @HiveField(10)
  late int gamesPlayed;

  @HiveField(11)
  late int tournamentsWon;

  PlayerProfile({
    String? id,
    required this.name,
    this.avatarEmoji = '🎮',
    this.wins = 0,
    this.losses = 0,
    this.coins = 500,
    this.xp = 0,
    this.level = 1,
    this.winStreak = 0,
    this.bestRank = 0,
    this.gamesPlayed = 0,
    this.tournamentsWon = 0,
  }) {
    this.id = id ?? const Uuid().v4();
  }

  double get winRate => gamesPlayed == 0 ? 0 : (wins / gamesPlayed * 100);

  int get xpForNextLevel => level * 500;

  void addWin({int coinsEarned = 100, int xpEarned = 200}) {
    wins++;
    gamesPlayed++;
    coins += coinsEarned;
    xp += xpEarned;
    winStreak++;
    _checkLevelUp();
  }

  void addLoss({int xpEarned = 50}) {
    losses++;
    gamesPlayed++;
    xp += xpEarned;
    winStreak = 0;
    _checkLevelUp();
  }

  void _checkLevelUp() {
    while (xp >= xpForNextLevel) {
      xp -= xpForNextLevel;
      level++;
      coins += 200; // level-up bonus
    }
  }
}
