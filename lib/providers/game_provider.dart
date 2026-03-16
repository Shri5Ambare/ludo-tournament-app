// lib/providers/game_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../game_engine/game_engine.dart';
import '../ai/ai_engine.dart';
import '../core/constants/app_constants.dart';
import '../services/audio_service.dart';

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
    _ref.read(audioServiceProvider).playDiceRoll();
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
    final newState = GameEngine.moveToken(currentState, tokenId);
    state = newState;
    _playMoveSound(currentState, newState, tokenId);
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
      _ref.read(audioServiceProvider).playDiceRoll();
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
          final newS = GameEngine.moveToken(s, tokenId);
          _playMoveSound(s, newS, tokenId);
          state = newS;
          _afterStateUpdate();
        },
      );
    }
  }

  void _afterStateUpdate() {
    final currentState = state;
    if (currentState == null) return;

    // Win sound
    if (currentState.isFinished) {
      _ref.read(audioServiceProvider).playWin();
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

  /// Play the right sound based on what changed between before/after move
  void _playMoveSound(GameState before, GameState after, int tokenId) {
    final audio = _ref.read(audioServiceProvider);

    // Check if a token was cut (opponent token returned home)
    int beforeActive = before.players
        .expand((p) => p.tokens)
        .where((t) => t.isActive)
        .length;
    int afterActive = after.players
        .expand((p) => p.tokens)
        .where((t) => t.isActive)
        .length;
    if (afterActive < beforeActive) {
      audio.playTokenCut();
      return;
    }

    // Check if our token just finished (reached home)
    final playerIdx = before.currentPlayerIndex;
    final beforeFinished = before.players[playerIdx].tokens
        .where((t) => t.isFinished).length;
    final afterFinished = after.players[playerIdx].tokens
        .where((t) => t.isFinished).length;
    if (afterFinished > beforeFinished) {
      audio.playTokenHome();
      return;
    }

    // Regular move
    audio.playTokenMove();
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
