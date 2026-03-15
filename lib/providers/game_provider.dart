// lib/providers/game_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../game_engine/game_engine.dart';
import '../ai/ai_engine.dart';
import '../core/constants/app_constants.dart';
import 'settings_provider.dart';

// ─────────────────────────────────────────────
// Game Provider
// ─────────────────────────────────────────────

final gameProvider = StateNotifierProvider<GameNotifier, GameState?>((ref) {
  return GameNotifier(ref);
});

class GameNotifier extends StateNotifier<GameState?> {
  final Ref _ref;
  Timer? _turnTimer;
  Timer? _aiTimer;

  GameNotifier(this._ref) : super(null);

  /// Initialize a new game
  void initGame({
    required List<Map<String, dynamic>> playerConfigs,
    String gameMode = GameMode.classic,
    int turnTimerSeconds = AppConstants.defaultTurnSeconds,
  }) {
    _cancelTimers();
    final initialState = GameEngine.createInitialState(
      playerConfigs: playerConfigs,
      gameMode: gameMode,
      turnTimerSeconds: turnTimerSeconds,
    );
    state = initialState;
    _startTurnTimer();
    _triggerAIIfNeeded();
  }

  /// Roll the dice
  void rollDice() {
    final currentState = state;
    if (currentState == null) return;
    if (currentState.hasRolled) return;
    if (currentState.phase != GamePhase.rolling) return;
    if (currentState.currentPlayer.isAI) return;

    _cancelTimers();
    final diceValue = GameEngine.rollDice();
    state = GameEngine.applyDiceRoll(currentState, diceValue);
    _afterStateUpdate();
  }

  /// Select a token to move (called when player taps token)
  void selectToken(int tokenId) {
    final currentState = state;
    if (currentState == null) return;
    if (currentState.phase != GamePhase.moving) return;
    if (!currentState.movableTokenIds.contains(tokenId)) return;
    if (currentState.currentPlayer.isAI) return;

    _cancelTimers();
    state = GameEngine.moveToken(currentState, tokenId);
    _afterStateUpdate();
  }

  /// Reset game
  void resetGame() {
    _cancelTimers();
    state = null;
  }

  // ─────────────────────────────────────────────
  // Turn Timer
  // ─────────────────────────────────────────────

  void _startTurnTimer() {
    final currentState = state;
    if (currentState == null) return;

    _turnTimer?.cancel();
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final s = state;
      if (s == null || s.isFinished) {
        timer.cancel();
        return;
      }
      if (s.remainingTurnSeconds <= 1) {
        timer.cancel();
        _autoSkipTurn();
      } else {
        state = s.copyWith(
          remainingTurnSeconds: s.remainingTurnSeconds - 1,
        );
      }
    });
  }

  void _autoSkipTurn() {
    final currentState = state;
    if (currentState == null) return;
    // Auto-roll if not rolled yet
    if (!currentState.hasRolled) {
      final diceValue = GameEngine.rollDice();
      state = GameEngine.applyDiceRoll(currentState, diceValue);
      _afterStateUpdate();
      return;
    }
    // Auto-pick first movable token
    if (currentState.movableTokenIds.isNotEmpty) {
      state = GameEngine.moveToken(currentState, currentState.movableTokenIds.first);
      _afterStateUpdate();
    }
  }

  // ─────────────────────────────────────────────
  // AI Logic
  // ─────────────────────────────────────────────

  void _triggerAIIfNeeded() {
    final currentState = state;
    if (currentState == null || currentState.isFinished) return;
    if (!currentState.currentPlayer.isAI) return;

    _aiTimer?.cancel();
    _aiTimer = Timer(
      Duration(milliseconds: AppConstants.aiThinkDelayMs),
      _executeAITurn,
    );
  }

  void _executeAITurn() {
    final currentState = state;
    if (currentState == null || currentState.isFinished) return;
    final player = currentState.currentPlayer;
    if (!player.isAI) return;

    if (!currentState.hasRolled) {
      // AI rolls
      final diceValue = GameEngine.rollDice();
      state = GameEngine.applyDiceRoll(currentState, diceValue);
      _afterStateUpdate();
    } else if (currentState.movableTokenIds.isNotEmpty) {
      // AI picks token
      _aiTimer?.cancel();
      _aiTimer = Timer(
        Duration(milliseconds: AppConstants.aiMoveDelayMs),
        () {
          final s = state;
          if (s == null) return;
          final tokenId = AIEngine.chooseToken(
            player: s.currentPlayer,
            movableTokenIds: s.movableTokenIds,
            allPlayers: s.players,
            diceValue: s.diceValue,
            difficulty: s.currentPlayer.aiDifficulty,
          );
          state = GameEngine.moveToken(s, tokenId);
          _afterStateUpdate();
        },
      );
    }
  }

  void _afterStateUpdate() {
    final currentState = state;
    if (currentState == null || currentState.isFinished) {
      _cancelTimers();
      return;
    }
    // Reset turn timer
    state = currentState.copyWith(
      remainingTurnSeconds: currentState.turnTimeSeconds,
    );
    _startTurnTimer();
    _triggerAIIfNeeded();
  }

  void _cancelTimers() {
    _turnTimer?.cancel();
    _aiTimer?.cancel();
    _turnTimer = null;
    _aiTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
