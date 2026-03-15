// lib/game_engine/game_engine.dart
import 'dart:math';
import '../models/game_models.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/board_paths.dart';

/// Core Ludo game engine - handles all game logic
class GameEngine {
  static final Random _random = Random();

  // ─────────────────────────────────────────────
  // Dice
  // ─────────────────────────────────────────────

  /// Roll the dice, returns 1-6
  static int rollDice() {
    return _random.nextInt(6) + 1;
  }

  // ─────────────────────────────────────────────
  // Movable tokens
  // ─────────────────────────────────────────────

  /// Get list of token IDs that can be moved given dice value
  static List<int> getMovableTokens(Player player, int diceValue) {
    final movable = <int>[];

    for (final token in player.tokens) {
      if (token.isFinished) continue;

      if (token.isAtHome) {
        // Can only unlock from home on a 6
        if (diceValue == 6) movable.add(token.id);
      } else {
        // Can move if won't overshoot final position
        final newPos = token.position + diceValue;
        final maxPos = 57; // 52 main + 6 home column - 1 (0-indexed)
        if (newPos <= maxPos) movable.add(token.id);
      }
    }
    return movable;
  }

  // ─────────────────────────────────────────────
  // Move a token
  // ─────────────────────────────────────────────

  /// Apply a token move. Returns updated GameState.
  static GameState moveToken(GameState state, int tokenId) {
    final currentPlayer = state.currentPlayer;
    final tokenIndex = currentPlayer.tokens.indexWhere((t) => t.id == tokenId);
    if (tokenIndex == -1) return state;

    Token token = currentPlayer.tokens[tokenIndex];
    List<Player> players = List.from(state.players);
    List<String> log = List.from(state.eventLog);

    // Calculate new position
    int newPosition;
    TokenState newState;

    if (token.isAtHome) {
      // Unlock: place at start (position 0)
      newPosition = 0;
      newState = TokenState.active;
      log.add('${currentPlayer.name} unlocked a token!');
    } else {
      newPosition = token.position + state.diceValue;

      if (newPosition == 57) {
        // Token reaches home center
        newState = TokenState.finished;
        newPosition = 58;
        log.add('${currentPlayer.name}\'s token reached HOME! 🎉');
      } else if (newPosition > 51) {
        // In home column
        newState = TokenState.safe;
        log.add('${currentPlayer.name} moved into home column.');
      } else if (BoardPaths.isSafePosition(currentPlayer.index, newPosition)) {
        newState = TokenState.safe;
        log.add('${currentPlayer.name} moved to a safe zone!');
      } else {
        newState = TokenState.active;
        log.add('${currentPlayer.name} moved a token.');
      }
    }

    // Update the moved token
    final updatedToken = token.copyWith(state: newState, position: newPosition);
    final updatedTokens = List<Token>.from(currentPlayer.tokens);
    updatedTokens[tokenIndex] = updatedToken;

    // Check for cuts (only on main path, non-safe positions)
    if (newState == TokenState.active && newPosition <= 51) {
      players = _applyCuts(
        players: players,
        movingPlayerIndex: currentPlayer.index,
        newPosition: newPosition,
        log: log,
      );
    }

    // Update current player with new token
    final updatedPlayer = currentPlayer.copyWith(tokens: updatedTokens);
    players[currentPlayer.index] = updatedPlayer;

    // Check if player has won
    final hasWon = updatedTokens.every((t) => t.isFinished);
    int? winnerId;
    int? currentWinnersCount = players.where((p) => p.rank > 0).length;

    if (hasWon) {
      final rank = currentWinnersCount + 1;
      players[currentPlayer.index] = updatedPlayer.copyWith(rank: rank);
      log.add('🏆 ${currentPlayer.name} finished in place $rank!');
      if (rank == 1) winnerId = currentPlayer.index;
    }

    // Determine next turn
    final bool extraTurn = state.diceValue == 6 && !hasWon;
    final int consecutiveSixes = extraTurn ? state.consecutiveSixes + 1 : 0;

    // 3 consecutive sixes: lose turn and reset
    if (consecutiveSixes >= 3) {
      log.add('${currentPlayer.name} rolled 3 sixes - turn forfeited!');
      final nextPlayer = _nextActivePlayer(players, currentPlayer.index);
      return state.copyWith(
        players: players,
        currentPlayerIndex: nextPlayer,
        diceValue: 0,
        hasRolled: false,
        phase: _isGameOver(players) ? GamePhase.finished : GamePhase.rolling,
        movableTokenIds: [],
        consecutiveSixes: 0,
        eventLog: log,
        winnerId: winnerId,
      );
    }

    if (extraTurn) {
      // Same player rolls again
      log.add('${currentPlayer.name} gets another turn! 🎲');
      return state.copyWith(
        players: players,
        diceValue: 0,
        hasRolled: false,
        phase: GamePhase.rolling,
        movableTokenIds: [],
        consecutiveSixes: consecutiveSixes,
        eventLog: log,
        winnerId: winnerId,
      );
    }

    // Move to next player
    final nextPlayer = _nextActivePlayer(players, currentPlayer.index);
    return state.copyWith(
      players: players,
      currentPlayerIndex: nextPlayer,
      diceValue: 0,
      hasRolled: false,
      phase: _isGameOver(players) ? GamePhase.finished : GamePhase.rolling,
      movableTokenIds: [],
      consecutiveSixes: 0,
      eventLog: log,
      winnerId: winnerId,
    );
  }

  // ─────────────────────────────────────────────
  // Apply Dice Roll to State
  // ─────────────────────────────────────────────

  static GameState applyDiceRoll(GameState state, int diceValue) {
    final player = state.currentPlayer;
    final movable = getMovableTokens(player, diceValue);
    List<String> log = List.from(state.eventLog);
    log.add('${player.name} rolled a $diceValue');

    // No movable tokens: skip turn
    if (movable.isEmpty) {
      log.add('${player.name} has no moves. Turn skipped.');
      final next = _nextActivePlayer(state.players, player.index);
      return state.copyWith(
        diceValue: diceValue,
        hasRolled: true,
        phase: GamePhase.rolling,
        movableTokenIds: [],
        currentPlayerIndex: next,
        consecutiveSixes: 0,
        eventLog: log,
      ).copyWith(
        diceValue: 0,
        hasRolled: false,
      );
    }

    // Only one movable token: auto-select it
    if (movable.length == 1) {
      final afterRoll = state.copyWith(
        diceValue: diceValue,
        hasRolled: true,
        phase: GamePhase.moving,
        movableTokenIds: movable,
        consecutiveSixes: state.consecutiveSixes,
        eventLog: log,
      );
      return moveToken(afterRoll, movable.first);
    }

    // Multiple movable tokens: wait for player selection
    return state.copyWith(
      diceValue: diceValue,
      hasRolled: true,
      phase: GamePhase.moving,
      movableTokenIds: movable,
      consecutiveSixes: state.consecutiveSixes,
      eventLog: log,
    );
  }

  // ─────────────────────────────────────────────
  // Cuts
  // ─────────────────────────────────────────────

  static List<Player> _applyCuts({
    required List<Player> players,
    required int movingPlayerIndex,
    required int newPosition,
    required List<String> log,
  }) {
    final updatedPlayers = List<Player>.from(players);

    for (int i = 0; i < players.length; i++) {
      if (i == movingPlayerIndex) continue;
      final opponent = players[i];

      // Check each token of opponent
      final updatedTokens = opponent.tokens.map((t) {
        if (t.isAtHome || t.isFinished || t.position > 51) return t;
        if (!t.isActive) return t; // safe tokens can't be cut

        // Convert opponent's position to absolute board position
        final opponentAbsPos =
            (t.position + BoardPaths.playerStartIndex[i]) % 52;
        final movingAbsPos =
            (newPosition + BoardPaths.playerStartIndex[movingPlayerIndex]) % 52;

        if (opponentAbsPos == movingAbsPos && !BoardPaths.safePositions.contains(opponentAbsPos)) {
          log.add(
              '✂️ ${players[movingPlayerIndex].name} cut ${opponent.name}\'s token!');
          return t.copyWith(state: TokenState.home, position: -1);
        }
        return t;
      }).toList();

      updatedPlayers[i] = opponent.copyWith(tokens: updatedTokens);
    }
    return updatedPlayers;
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  static int _nextActivePlayer(List<Player> players, int current) {
    int next = (current + 1) % players.length;
    // Skip players who have finished
    int attempts = 0;
    while (players[next].hasWon && attempts < players.length) {
      next = (next + 1) % players.length;
      attempts++;
    }
    return next;
  }

  static bool _isGameOver(List<Player> players) {
    final activePlayers = players.where((p) => !p.hasWon).length;
    return activePlayers <= 1;
  }

  /// Create initial game state from player configs
  static GameState createInitialState({
    required List<Map<String, dynamic>> playerConfigs,
    String gameMode = GameMode.classic,
    int turnTimerSeconds = AppConstants.defaultTurnSeconds,
  }) {
    final players = <Player>[];

    for (int i = 0; i < playerConfigs.length; i++) {
      final config = playerConfigs[i];
      final tokens = List.generate(
        AppConstants.tokensPerPlayer,
        (j) => Token(id: j, playerIndex: i),
      );
      players.add(Player(
        index: i,
        name: config['name'] as String? ?? BoardPaths.playerColorNames[i],
        type: config['type'] as PlayerType? ?? PlayerType.human,
        aiDifficulty: config['difficulty'] as String? ?? AIDifficulty.medium,
        tokens: tokens,
        avatarEmoji: config['avatar'] as String? ?? '🎮',
      ));
    }

    return GameState(
      players: players,
      phase: GamePhase.rolling,
      gameMode: gameMode,
      turnTimeSeconds: turnTimerSeconds,
      remainingTurnSeconds: turnTimerSeconds,
    );
  }
}
