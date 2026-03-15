// lib/providers/tournament_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/tournament_model.dart';
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
  }) {
    final groups = TournamentState.buildGroups(playerNames);
    state = TournamentState(
      id: const Uuid().v4(),
      name: name,
      groups: groups,
      type: type,
      gameMode: gameMode,
      turnTimerSeconds: turnTimerSeconds,
      status: TournamentStatus.inProgress,
    );
  }

  /// Mark a group game as complete with a winner
  void completeGroupGame(int groupIndex, String winnerName) {
    final current = state;
    if (current == null) return;

    current.groups[groupIndex].winnerName = winnerName;
    current.groups[groupIndex].isComplete = true;

    // Check if all groups are done
    if (current.isGroupStageComplete) {
      _startFinals();
    } else {
      state = TournamentState(
        id: current.id,
        name: current.name,
        groups: current.groups,
        type: current.type,
        gameMode: current.gameMode,
        turnTimerSeconds: current.turnTimerSeconds,
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
      currentRound: current.currentRound,
      roundWinners: current.roundWinners,
      champion: TournamentPlayer(name: championName),
      status: TournamentStatus.completed,
    );
  }

  void reset() => state = null;
}
