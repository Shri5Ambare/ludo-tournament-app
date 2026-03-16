// lib/game_engine/game_engine.dart
import 'dart:math';
import '../models/game_models.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/board_paths.dart';

/// Core Ludo game engine — all game logic lives here
class GameEngine {
  static final Random _random = Random();

  // ── Dice ───────────────────────────────────────────────────────────────────

  static int rollDice() => _random.nextInt(6) + 1;

  // ── Quick mode: dice cap at 4 for faster games ─────────────────────────────

  static int rollDiceForMode(String gameMode) {
    final value = rollDice();
    // Quick mode: tokens need only 28 steps to home (not 57)
    return value;
  }

  // ── Movable tokens ─────────────────────────────────────────────────────────

  static List<int> getMovableTokens(Player player, int diceValue,
      {String gameMode = GameMode.classic}) {
    final movable = <int>[];
    final maxPos = gameMode == GameMode.quick ? 28 : 57;

    for (final token in player.tokens) {
      if (token.isFinished) continue;

      if (token.isAtHome) {
        if (diceValue == 6) movable.add(token.id);
      } else {
        final newPos = token.position + diceValue;
        if (newPos <= maxPos) movable.add(token.id);
      }
    }
    return movable;
  }

  // ── Move token ─────────────────────────────────────────────────────────────

  static GameState moveToken(GameState state, int tokenId) {
    final currentPlayer = state.currentPlayer;
    final tokenIndex =
        currentPlayer.tokens.indexWhere((t) => t.id == tokenId);
    if (tokenIndex == -1) return state;

    final token = currentPlayer.tokens[tokenIndex];
    List<Player> players = List.from(state.players);
    List<String> log = List.from(state.eventLog);

    final maxPos = state.gameMode == GameMode.quick ? 28 : 57;
    final homeColumnStart =
        state.gameMode == GameMode.quick ? 23 : 52;

    int newPosition;
    TokenState newState;

    if (token.isAtHome) {
      newPosition = 0;
      newState = TokenState.active;
      log.add('${currentPlayer.name} unlocked a token! 🔓');
    } else {
      newPosition = token.position + state.diceValue;

      if (newPosition >= maxPos) {
        // Exactly reached or overshot center — only move if exact
        if (newPosition == maxPos) {
          newState = TokenState.finished;
          newPosition = 58; // sentinel for center
          log.add('${currentPlayer.name}\'s token reached HOME! 🏠🎉');
        } else {
          // Overshoot — shouldn't happen (filtered in getMovableTokens) 
          return state;
        }
      } else if (newPosition >= homeColumnStart) {
        newState = TokenState.safe;
        log.add('${currentPlayer.name} entered home column.');
      } else if (BoardPaths.isSafePosition(
          currentPlayer.index, newPosition)) {
        newState = TokenState.safe;
        log.add('${currentPlayer.name} is on a safe star ⭐');
      } else {
        newState = TokenState.active;
      }
    }

    final updatedToken =
        token.copyWith(state: newState, position: newPosition);
    final updatedTokens = List<Token>.from(currentPlayer.tokens);
    updatedTokens[tokenIndex] = updatedToken;

    // Cuts — only on main path, non-safe
    if (newState == TokenState.active &&
        newPosition < homeColumnStart) {
      players = _applyCuts(
        players: players,
        movingPlayerIndex: currentPlayer.index,
        newPosition: newPosition,
        log: log,
      );
    }

    final updatedPlayer = currentPlayer.copyWith(tokens: updatedTokens);
    players[currentPlayer.index] = updatedPlayer;

    // Rank assignment
    final hasWon = updatedTokens.every((t) => t.isFinished);
    int? winnerId;
    if (hasWon) {
      final rank = players.where((p) => p.rank > 0).length + 1;
      players[currentPlayer.index] = updatedPlayer.copyWith(rank: rank);
      log.add('🏆 ${currentPlayer.name} finished #$rank!');
      if (rank == 1) winnerId = currentPlayer.index;
    }

    // Extra turn on 6 (unless just won)
    final bool extraTurn = state.diceValue == 6 && !hasWon;
    final int consSixes =
        extraTurn ? state.consecutiveSixes + 1 : 0;

    // 3 sixes in a row → forfeit
    if (consSixes >= 3) {
      log.add('${currentPlayer.name} rolled 3 sixes — turn forfeited!');
      return state.copyWith(
        players: players,
        currentPlayerIndex:
            _nextActivePlayer(players, currentPlayer.index),
        diceValue: 0,
        hasRolled: false,
        phase: _isGameOver(players) ? GamePhase.finished : GamePhase.rolling,
        movableTokenIds: [],
        consecutiveSixes: 0,
        eventLog: _trimLog(log),
        winnerId: winnerId,
      );
    }

    if (extraTurn) {
      log.add('${currentPlayer.name} gets another roll! 🎲');
      return state.copyWith(
        players: players,
        diceValue: 0,
        hasRolled: false,
        phase: GamePhase.rolling,
        movableTokenIds: [],
        consecutiveSixes: consSixes,
        eventLog: _trimLog(log),
        winnerId: winnerId,
      );
    }

    return state.copyWith(
      players: players,
      currentPlayerIndex:
          _nextActivePlayer(players, currentPlayer.index),
      diceValue: 0,
      hasRolled: false,
      phase: _isGameOver(players) ? GamePhase.finished : GamePhase.rolling,
      movableTokenIds: [],
      consecutiveSixes: 0,
      eventLog: _trimLog(log),
      winnerId: winnerId,
    );
  }

  // ── Apply dice roll ────────────────────────────────────────────────────────

  static GameState applyDiceRoll(GameState state, int diceValue) {
    final player = state.currentPlayer;
    final movable = getMovableTokens(player, diceValue,
        gameMode: state.gameMode);
    List<String> log = List.from(state.eventLog);
    log.add('${player.name} rolled a $diceValue');

    if (movable.isEmpty) {
      // No moves: skip turn (but 6 with all tokens home = skip too)
      log.add('${player.name} has no moves — skipped.');
      final next = _nextActivePlayer(state.players, player.index);
      // Reset timer too
      final s = state.copyWith(
        diceValue: diceValue,
        hasRolled: true,
        currentPlayerIndex: next,
        phase: GamePhase.rolling,
        movableTokenIds: [],
        consecutiveSixes: 0,
        eventLog: _trimLog(log),
      );
      return s.copyWith(diceValue: 0, hasRolled: false,
          remainingTurnSeconds: s.turnTimeSeconds);
    }

    // Auto-move if only one token can move
    if (movable.length == 1) {
      final afterRoll = state.copyWith(
        diceValue: diceValue,
        hasRolled: true,
        phase: GamePhase.moving,
        movableTokenIds: movable,
        consecutiveSixes: state.consecutiveSixes,
        eventLog: _trimLog(log),
      );
      return moveToken(afterRoll, movable.first);
    }

    return state.copyWith(
      diceValue: diceValue,
      hasRolled: true,
      phase: GamePhase.moving,
      movableTokenIds: movable,
      consecutiveSixes: state.consecutiveSixes,
      eventLog: _trimLog(log),
    );
  }

  // ── Cuts ───────────────────────────────────────────────────────────────────

  static List<Player> _applyCuts({
    required List<Player> players,
    required int movingPlayerIndex,
    required int newPosition,
    required List<String> log,
  }) {
    final updated = List<Player>.from(players);
    final movingAbsPos =
        (newPosition + BoardPaths.playerStartIndex[movingPlayerIndex]) % 52;

    // Skip if this is a safe position
    if (BoardPaths.safePositions.contains(movingAbsPos)) return players;

    for (int i = 0; i < players.length; i++) {
      if (i == movingPlayerIndex) continue;
      final opponent = players[i];
      final newTokens = opponent.tokens.map((t) {
        if (t.isAtHome || t.isFinished || t.position > 51) return t;
        if (t.state == TokenState.safe) return t; // safe tokens immune

        final oppAbsPos =
            (t.position + BoardPaths.playerStartIndex[i]) % 52;
        if (oppAbsPos == movingAbsPos) {
          log.add(
              '✂️ ${players[movingPlayerIndex].name} cut ${opponent.name}\'s token! Back to home.');
          return t.copyWith(state: TokenState.home, position: -1);
        }
        return t;
      }).toList();
      updated[i] = opponent.copyWith(tokens: newTokens);
    }
    return updated;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static int _nextActivePlayer(List<Player> players, int current) {
    int next = (current + 1) % players.length;
    int attempts = 0;
    while (players[next].hasWon && attempts < players.length) {
      next = (next + 1) % players.length;
      attempts++;
    }
    return next;
  }

  static bool _isGameOver(List<Player> players) {
    return players.where((p) => !p.hasWon).length <= 1;
  }

  // Keep log size bounded so widget rebuilds stay fast
  static List<String> _trimLog(List<String> log) {
    if (log.length > 30) return log.sublist(log.length - 30);
    return log;
  }

  // ── Create initial state ───────────────────────────────────────────────────

  static GameState createInitialState({
    required List<Map<String, dynamic>> playerConfigs,
    String gameMode = GameMode.classic,
    int turnTimerSeconds = AppConstants.defaultTurnSeconds,
  }) {
    final players = playerConfigs.asMap().entries.map((e) {
      final i = e.key;
      final cfg = e.value;
      return Player(
        index: i,
        name: cfg['name'] as String? ?? BoardPaths.playerColorNames[i],
        type: cfg['type'] as PlayerType? ?? PlayerType.human,
        aiDifficulty:
            cfg['difficulty'] as String? ?? AIDifficulty.medium,
        tokens: List.generate(
            AppConstants.tokensPerPlayer,
            (j) => Token(id: j, playerIndex: i)),
        avatarEmoji: cfg['avatar'] as String? ?? '🎮',
      );
    }).toList();

    return GameState(
      players: players,
      phase: GamePhase.rolling,
      gameMode: gameMode,
      turnTimeSeconds: turnTimerSeconds,
      remainingTurnSeconds: turnTimerSeconds,
    );
  }
}
