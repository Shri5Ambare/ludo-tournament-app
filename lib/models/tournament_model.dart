// lib/models/tournament_model.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';

part 'tournament_model.g.dart';

enum TournamentStatus { setup, inProgress, completed }
enum TournamentType { offline, hotspot, online }

@HiveType(typeId: 1)
class TournamentModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late List<String> playerNames;

  @HiveField(3)
  late List<String> groupAssignments; // JSON encoded groups

  @HiveField(4)
  late String status; // TournamentStatus name

  @HiveField(5)
  late String type; // TournamentType name

  @HiveField(6)
  late String? championName;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late String gameMode;

  @HiveField(9)
  late int turnTimerSeconds;

  TournamentModel({
    String? id,
    required this.name,
    required this.playerNames,
    this.groupAssignments = const [],
    this.status = 'setup',
    this.type = 'offline',
    this.championName,
    DateTime? createdAt,
    this.gameMode = GameMode.classic,
    this.turnTimerSeconds = AppConstants.defaultTurnSeconds,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
  }
}

/// Represents one tournament group (up to 4 players)
class TournamentGroup {
  final int groupIndex;
  final List<TournamentPlayer> players;
  String? winnerName;
  bool isComplete;

  TournamentGroup({
    required this.groupIndex,
    required this.players,
    this.winnerName,
    this.isComplete = false,
  });

  String get groupLabel => 'Group ${String.fromCharCode(65 + groupIndex)}'; // A, B, C, D
}

/// A player within a tournament
class TournamentPlayer {
  final String name;
  final bool isBot;
  final String avatarEmoji;

  const TournamentPlayer({
    required this.name,
    this.isBot = false,
    this.avatarEmoji = '🎮',
  });
}

/// Full tournament state (in-memory, not persisted to Hive directly)
class TournamentState {
  final String id;
  final String name;
  final List<TournamentGroup> groups;
  final TournamentType type;
  final String gameMode;
  final int turnTimerSeconds;
  int currentRound; // 1 = group stage, 2 = finals
  List<TournamentPlayer> roundWinners;
  TournamentPlayer? champion;
  TournamentStatus status;

  TournamentState({
    required this.id,
    required this.name,
    required this.groups,
    required this.type,
    this.gameMode = GameMode.classic,
    this.turnTimerSeconds = AppConstants.defaultTurnSeconds,
    this.currentRound = 1,
    this.roundWinners = const [],
    this.champion,
    this.status = TournamentStatus.setup,
  });

  bool get isGroupStageComplete =>
      groups.every((g) => g.isComplete);

  bool get isComplete => status == TournamentStatus.completed;

  int get totalPlayers =>
      groups.fold(0, (sum, g) => sum + g.players.length);

  /// Build groups from player names, filling with bots if uneven
  static List<TournamentGroup> buildGroups(List<String> playerNames) {
    final allPlayers = List<String>.from(playerNames);
    final groups = <TournamentGroup>[];
    int groupIndex = 0;

    while (allPlayers.isNotEmpty) {
      final groupPlayers = <TournamentPlayer>[];
      for (int i = 0; i < AppConstants.playersPerGroup && allPlayers.isNotEmpty; i++) {
        groupPlayers.add(TournamentPlayer(name: allPlayers.removeAt(0)));
      }
      // Fill remaining slots with bots
      while (groupPlayers.length < AppConstants.playersPerGroup) {
        groupPlayers.add(TournamentPlayer(
          name: 'Bot ${groupIndex + 1}-${groupPlayers.length + 1}',
          isBot: true,
          avatarEmoji: '🤖',
        ));
      }
      groups.add(TournamentGroup(
        groupIndex: groupIndex,
        players: groupPlayers,
      ));
      groupIndex++;
    }
    return groups;
  }
}
