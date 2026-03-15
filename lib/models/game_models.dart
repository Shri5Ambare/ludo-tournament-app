// lib/models/game_models.dart
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../core/constants/board_paths.dart';
import '../core/constants/app_constants.dart';

// ─────────────────────────────────────────────
// Token State
// ─────────────────────────────────────────────

enum TokenState { home, active, safe, finished }

class Token extends Equatable {
  final int id;           // 0-3
  final int playerIndex;  // 0-3
  final TokenState state;
  final int position;     // -1=home, 0-51=main path, 52-57=home column, 58=center

  const Token({
    required this.id,
    required this.playerIndex,
    this.state = TokenState.home,
    this.position = -1,
  });

  bool get isAtHome => state == TokenState.home;
  bool get isFinished => state == TokenState.finished;
  bool get isActive => state == TokenState.active || state == TokenState.safe;

  bool get isSafe {
    if (isAtHome || isFinished) return true;
    return BoardPaths.isSafePosition(playerIndex, position);
  }

  Token copyWith({
    TokenState? state,
    int? position,
  }) {
    return Token(
      id: id,
      playerIndex: playerIndex,
      state: state ?? this.state,
      position: position ?? this.position,
    );
  }

  /// Get the pixel grid coordinates of this token
  List<int> get boardCell {
    if (isAtHome) return BoardPaths.homeYards[playerIndex]![id];
    if (isFinished) return BoardPaths.centerCell;
    if (position <= 51) {
      return BoardPaths.getMainPathCell(playerIndex, position);
    } else {
      return BoardPaths.getHomeColumnCell(playerIndex, position - 52);
    }
  }

  @override
  List<Object?> get props => [id, playerIndex, state, position];
}

// ─────────────────────────────────────────────
// Player Model
// ─────────────────────────────────────────────

enum PlayerType { human, ai, remote }

class Player extends Equatable {
  final int index;         // 0-3
  final String name;
  final PlayerType type;
  final String aiDifficulty;
  final List<Token> tokens;
  final int rank;          // 0=not finished, 1=1st, 2=2nd etc.
  final int score;
  final String avatarEmoji;

  const Player({
    required this.index,
    required this.name,
    this.type = PlayerType.human,
    this.aiDifficulty = AIDifficulty.medium,
    required this.tokens,
    this.rank = 0,
    this.score = 0,
    this.avatarEmoji = '🎮',
  });

  Color get color => BoardPaths.playerColors[index];
  String get colorName => BoardPaths.playerColorNames[index];
  bool get isAI => type == PlayerType.ai;
  bool get hasFinished => rank > 0;

  int get finishedTokenCount =>
      tokens.where((t) => t.isFinished).length;

  bool get hasWon => finishedTokenCount == AppConstants.tokensPerPlayer;

  List<Token> get activeTokens =>
      tokens.where((t) => t.isActive).toList();

  List<Token> get homeTokens =>
      tokens.where((t) => t.isAtHome).toList();

  Player copyWith({
    String? name,
    PlayerType? type,
    List<Token>? tokens,
    int? rank,
    int? score,
  }) {
    return Player(
      index: index,
      name: name ?? this.name,
      type: type ?? this.type,
      aiDifficulty: aiDifficulty,
      tokens: tokens ?? this.tokens,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      avatarEmoji: avatarEmoji,
    );
  }

  @override
  List<Object?> get props => [index, name, type, tokens, rank, score];
}

// ─────────────────────────────────────────────
// Game State
// ─────────────────────────────────────────────

enum GamePhase { waiting, rolling, moving, finished }
enum GameResult { ongoing, playerWon }

class GameState extends Equatable {
  final List<Player> players;
  final int currentPlayerIndex;
  final int diceValue;
  final bool hasRolled;
  final GamePhase phase;
  final List<int> movableTokenIds; // token IDs that can be moved
  final int consecutiveSixes;
  final List<String> eventLog;
  final int? winnerId;
  final String gameMode;
  final int turnTimeSeconds;
  final int remainingTurnSeconds;

  const GameState({
    required this.players,
    this.currentPlayerIndex = 0,
    this.diceValue = 0,
    this.hasRolled = false,
    this.phase = GamePhase.waiting,
    this.movableTokenIds = const [],
    this.consecutiveSixes = 0,
    this.eventLog = const [],
    this.winnerId,
    this.gameMode = GameMode.classic,
    this.turnTimeSeconds = AppConstants.defaultTurnSeconds,
    this.remainingTurnSeconds = AppConstants.defaultTurnSeconds,
  });

  Player get currentPlayer => players[currentPlayerIndex];
  bool get isFinished => phase == GamePhase.finished;

  List<Player> get rankedPlayers {
    final finished = players.where((p) => p.hasFinished || p.rank > 0).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final unfinished = players.where((p) => !p.hasFinished && p.rank == 0).toList();
    return [...finished, ...unfinished];
  }

  GameState copyWith({
    List<Player>? players,
    int? currentPlayerIndex,
    int? diceValue,
    bool? hasRolled,
    GamePhase? phase,
    List<int>? movableTokenIds,
    int? consecutiveSixes,
    List<String>? eventLog,
    int? winnerId,
    int? remainingTurnSeconds,
  }) {
    return GameState(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      diceValue: diceValue ?? this.diceValue,
      hasRolled: hasRolled ?? this.hasRolled,
      phase: phase ?? this.phase,
      movableTokenIds: movableTokenIds ?? this.movableTokenIds,
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
      eventLog: eventLog ?? this.eventLog,
      winnerId: winnerId ?? this.winnerId,
      gameMode: gameMode,
      turnTimeSeconds: turnTimeSeconds,
      remainingTurnSeconds: remainingTurnSeconds ?? this.remainingTurnSeconds,
    );
  }

  @override
  List<Object?> get props => [
        players, currentPlayerIndex, diceValue, hasRolled,
        phase, movableTokenIds, consecutiveSixes, winnerId,
      ];
}
