// lib/providers/tournament_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/tournament_model.dart';
import '../models/game_models.dart';
import '../core/constants/app_constants.dart';

final tournamentProvider =
    StateNotifierProvider<TournamentNotifier, TournamentState?>((ref) {
  return TournamentNotifier();
});

class TournamentNotifier extends StateNotifier<TournamentState?> {
  TournamentNotifier() : super(null);

  /// Create and initialize a new tournament
  void createTournament({
    required String name,
    required List<String> playerNames,
    required TournamentType type,
    String gameMode = GameMode.classic,
    int turnTimerSeconds = AppConstants.defaultTurnSeconds,
    CustomRules customRules = const CustomRules(),
  }) {
    final groups = TournamentState.buildGroups(playerNames);
    state = TournamentState(
      id: const Uuid().v4(),
      name: name,
      groups: groups,
      type: type,
      gameMode: gameMode,
      turnTimerSeconds: turnTimerSeconds,
      customRules: customRules,
      status: TournamentStatus.inProgress,
    );
  }

  /// Mark a group game as complete with a winner
  void completeGroupGame(int groupIndex, String winnerName) {
    final current = state;
    if (current == null) return;

    final updatedGroups = List<TournamentGroup>.from(current.groups);
    final group = updatedGroups[groupIndex];
    updatedGroups[groupIndex] = TournamentGroup(
      groupIndex: group.groupIndex,
      players: group.players,
      winnerName: winnerName,
      isComplete: true,
    );
    
    // Check if all groups are done
    if (updatedGroups.every((g) => g.isComplete)) {
      _startFinals();
    } else {
      state = TournamentState(
        id: current.id,
        name: current.name,
        groups: updatedGroups,
        type: current.type,
        gameMode: current.gameMode,
        turnTimerSeconds: current.turnTimerSeconds,
        customRules: current.customRules,
        currentRound: current.currentRound,
        roundWinners: current.roundWinners,
        status: current.status,
      );
    }
  }

  void _startFinals() {
    final current = state;
    if (current == null) return;

    final winners = current.groups
        .where((g) => g.winnerName != null)
        .map((g) => TournamentPlayer(name: g.winnerName!))
        .toList();

    state = TournamentState(
      id: current.id,
      name: current.name,
      groups: current.groups,
      type: current.type,
      gameMode: current.gameMode,
      turnTimerSeconds: current.turnTimerSeconds,
      customRules: current.customRules,
      currentRound: 2,
      roundWinners: winners,
      status: TournamentStatus.inProgress,
    );
  }

  /// Complete the finals round
  void completeFinals(String championName) {
    final current = state;
    if (current == null) return;

    state = TournamentState(
      id: current.id,
      name: current.name,
      groups: current.groups,
      type: current.type,
      gameMode: current.gameMode,
      turnTimerSeconds: current.turnTimerSeconds,
      customRules: current.customRules,
      currentRound: current.currentRound,
      roundWinners: current.roundWinners,
      champion: TournamentPlayer(name: championName),
      status: TournamentStatus.completed,
    );
  }

  void reset() => state = null;
}
