// lib/ai/ai_engine.dart
import 'dart:math';
import '../models/game_models.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/board_paths.dart';
import 'game_engine.dart';

/// AI decision engine for bot players
class AIEngine {
  static final Random _random = Random();

  /// Choose the best token to move based on difficulty
  static int chooseToken({
    required Player player,
    required List<int> movableTokenIds,
    required List<Player> allPlayers,
    required int diceValue,
    required String difficulty,
  }) {
    if (movableTokenIds.length == 1) return movableTokenIds.first;

    switch (difficulty) {
      case AIDifficulty.easy:
        return _easyChoice(movableTokenIds);
      case AIDifficulty.hard:
        return _hardChoice(player, movableTokenIds, allPlayers, diceValue);
      case AIDifficulty.medium:
      default:
        return _mediumChoice(player, movableTokenIds, allPlayers, diceValue);
    }
  }

  // ─────────────────────────────────────────────
  // Easy: random choice
  // ─────────────────────────────────────────────
  static int _easyChoice(List<int> movableTokenIds) {
    return movableTokenIds[_random.nextInt(movableTokenIds.length)];
  }

  // ─────────────────────────────────────────────
  // Medium: prefer cuts and unlocks, otherwise advance furthest
  // ─────────────────────────────────────────────
  static int _mediumChoice(
    Player player,
    List<int> movableTokenIds,
    List<Player> allPlayers,
    int diceValue,
  ) {
    // Priority 1: unlock a token if rolling 6 and all locked
    final homeTokens = movableTokenIds
        .where((id) => player.tokens[id].isAtHome)
        .toList();
    if (homeTokens.isNotEmpty && player.activeTokens.isEmpty) {
      return homeTokens.first;
    }

    // Priority 2: if can cut an opponent
    for (final id in movableTokenIds) {
      if (_canCut(player, id, allPlayers, diceValue)) return id;
    }

    // Priority 3: move token closest to home
    return _tokenClosestToFinish(player, movableTokenIds);
  }

  // ─────────────────────────────────────────────
  // Hard: scored decision tree
  // ─────────────────────────────────────────────
  static int _hardChoice(
    Player player,
    List<int> movableTokenIds,
    List<Player> allPlayers,
    int diceValue,
  ) {
    int bestId = movableTokenIds.first;
    int bestScore = -999;

    for (final id in movableTokenIds) {
      final score = _scoreMove(player, id, allPlayers, diceValue);
      if (score > bestScore) {
        bestScore = score;
        bestId = id;
      }
    }
    return bestId;
  }

  static int _scoreMove(
    Player player,
    int tokenId,
    List<Player> allPlayers,
    int diceValue,
  ) {
    int score = 0;
    final token = player.tokens[tokenId];

    // Unlock token: +30
    if (token.isAtHome) return 30;

    final newPos = token.position + diceValue;

    // Reach home (finish): +100
    if (newPos == 57) return 100;

    // Enter home column: +40
    if (newPos > 51 && token.position <= 51) score += 40;

    // Move to safe zone: +25
    if (newPos <= 51 &&
        BoardPaths.isSafePosition(player.index, newPos)) score += 25;

    // Cut opponent: +50
    if (_canCut(player, tokenId, allPlayers, diceValue)) score += 50;

    // Advance progress: +distance/2
    score += diceValue ~/ 2;

    // Avoid danger zone (opponent near): -15
    if (_isInDanger(player, newPos, allPlayers)) score -= 15;

    // Prefer tokens already on board
    if (!token.isAtHome) score += 5;

    return score;
  }

  static bool _canCut(
    Player player,
    int tokenId,
    List<Player> allPlayers,
    int diceValue,
  ) {
    final token = player.tokens[tokenId];
    if (token.isAtHome) return false;
    final newPos = token.position + diceValue;
    if (newPos > 51) return false;

    final newAbsPos = (newPos + BoardPaths.playerStartIndex[player.index]) % 52;
    if (BoardPaths.safePositions.contains(newAbsPos)) return false;

    for (final opponent in allPlayers) {
      if (opponent.index == player.index) continue;
      for (final t in opponent.tokens) {
        if (!t.isActive || t.position > 51) continue;
        final oppAbsPos =
            (t.position + BoardPaths.playerStartIndex[opponent.index]) % 52;
        if (oppAbsPos == newAbsPos) return true;
      }
    }
    return false;
  }

  static bool _isInDanger(Player player, int newPos, List<Player> allPlayers) {
    if (newPos > 51) return false;
    final newAbsPos = (newPos + BoardPaths.playerStartIndex[player.index]) % 52;
    if (BoardPaths.safePositions.contains(newAbsPos)) return false;

    for (final opponent in allPlayers) {
      if (opponent.index == player.index) continue;
      for (final t in opponent.tokens) {
        if (!t.isActive || t.position > 51) continue;
        final oppAbsPos =
            (t.position + BoardPaths.playerStartIndex[opponent.index]) % 52;
        // Check if opponent is within 1-6 steps behind
        final diff = (newAbsPos - oppAbsPos + 52) % 52;
        if (diff >= 1 && diff <= 6) return true;
      }
    }
    return false;
  }

  static int _tokenClosestToFinish(Player player, List<int> movableTokenIds) {
    int bestId = movableTokenIds.first;
    int bestPos = -1;
    for (final id in movableTokenIds) {
      final token = player.tokens[id];
      if (token.position > bestPos) {
        bestPos = token.position;
        bestId = id;
      }
    }
    return bestId;
  }
}
