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

  static int rollDiceForMode(String gameMode) {
    return rollDice(); // Quick mode still uses 1-6
  }

  // ── Movable tokens ─────────────────────────────────────────────────────────

  static List<int> getMovableTokens(GameState state, Player player, int diceValue) {
    final rules = state.customRules;
    final movable = <int>[];
    final maxPos = state.gameMode == GameMode.quick ? 28 : 57;
    final homeColumnStart = state.gameMode == GameMode.quick ? 23 : 52;
    
    // Track potential cut moves for "mustCutIfCuttable" rule
    final cutMoves = <int>[];

    for (final token in player.tokens) {
      if (token.isFinished) continue;

      if (token.isAtHome) {
        if (diceValue == 1 || (diceValue == 6 && rules.sixBringsCoinOut)) {
          movable.add(token.id);
        }
      } else {
        final newPos = token.position + diceValue;
        
        // Check if moving past max
        if (newPos > maxPos) continue;
        
        // "Must cut to enter home lane" rule
        if (rules.mustCutToEnterHomeLane && !player.hasCut && newPos >= homeColumnStart) {
          continue; // Blocked from entering home lane!
        }

        // Check for cut
        if (rules.mustCutIfCuttable && newPos < homeColumnStart) {
          final movingAbsPos = (newPos + BoardPaths.playerStartIndex[player.index]) % 52;
          bool canCut = false;
          
          if (!rules.safeZonesEnabled || !BoardPaths.safePositions.contains(movingAbsPos)) {
            // Check opponents
            for (int i = 0; i < state.players.length; i++) {
              if (i == player.index) continue;
              final opp = state.players[i];
              for (final t in opp.tokens) {
                if (t.isAtHome || t.isFinished || t.position >= homeColumnStart) continue;
                if (t.state == TokenState.safe) continue;
                
                final oppAbsPos = (t.position + BoardPaths.playerStartIndex[i]) % 52;
                if (oppAbsPos == movingAbsPos) {
                  canCut = true;
                  break;
                }
              }
              if (canCut) break;
            }
          }
          if (canCut) cutMoves.add(token.id);
        }

        movable.add(token.id);
      }
    }

    // Enforce "mustCutIfCuttable"
    if (rules.mustCutIfCuttable && cutMoves.isNotEmpty) {
      return cutMoves;
    }

    return movable;
  }

  // ── Move token ─────────────────────────────────────────────────────────────

  static GameState moveToken(GameState state, int tokenId) {
    var currentPlayer = state.currentPlayer;
    final tokenIndex = currentPlayer.tokens.indexWhere((t) => t.id == tokenId);
    if (tokenIndex == -1) return state;

    final token = currentPlayer.tokens[tokenIndex];
    List<Player> players = List.from(state.players);
    List<String> log = List.from(state.eventLog);
    final rules = state.customRules;

    final maxPos = state.gameMode == GameMode.quick ? 28 : 57;
    final homeColumnStart = state.gameMode == GameMode.quick ? 23 : 52;

    int newPosition;
    TokenState newState;

    if (token.isAtHome) {
      newPosition = 0;
      newState = TokenState.active;
      log.add('${currentPlayer.name} unlocked a token! 🔓');
    } else {
      newPosition = token.position + state.diceValue;

      if (newPosition >= maxPos) {
        if (newPosition == maxPos) {
          newState = TokenState.finished;
          newPosition = 58; 
          log.add('${currentPlayer.name}\'s token reached HOME! 🏠🎉');
        } else {
          return state; // Overshoot
        }
      } else if (newPosition >= homeColumnStart) {
        newState = TokenState.safe;
        log.add('${currentPlayer.name} entered home column.');
      } else if (rules.safeZonesEnabled && BoardPaths.isSafePosition(currentPlayer.index, newPosition)) {
        newState = TokenState.safe;
        log.add('${currentPlayer.name} is on a safe star ⭐');
      } else {
        newState = TokenState.active;
      }
    }

    var updatedToken = token.copyWith(state: newState, position: newPosition);
    var updatedTokens = List<Token>.from(currentPlayer.tokens);
    updatedTokens[tokenIndex] = updatedToken;

    bool cutHappened = false;
    if (newState == TokenState.active && newPosition < homeColumnStart) {
      final oldPlayers = List<Player>.from(players);
      players = _applyCuts(
        players: players,
        movingPlayerIndex: currentPlayer.index,
        newPosition: newPosition,
        log: log,
        rules: rules,
      );
      cutHappened = players.any((p) {
        if (p.index == currentPlayer.index) return false;
        final oldP = oldPlayers[p.index];
        return p.tokens.where((t) => t.isAtHome).length >
               oldP.tokens.where((t) => t.isAtHome).length;
      });
    }

    // Update hasCut flag
    final hasCutNow = currentPlayer.hasCut || cutHappened;

    var updatedPlayer = currentPlayer.copyWith(tokens: updatedTokens, hasCut: hasCutNow);
    players[currentPlayer.index] = updatedPlayer;
    currentPlayer = updatedPlayer;

    // Rank assignment
    final hasWon = updatedTokens.every((t) => t.isFinished);
    int? winnerId;
    if (hasWon) {
      final rank = players.where((p) => p.rank > 0).length + 1;
      updatedPlayer = updatedPlayer.copyWith(rank: rank);
      players[currentPlayer.index] = updatedPlayer;
      log.add('🏆 ${currentPlayer.name} finished #$rank!');
      if (rank == 1) winnerId = currentPlayer.index;
    }

    // Extra turn rules
    bool extraTurn = false;
    if (state.diceValue == 6 && rules.sixGivesExtraTurn) extraTurn = true;
    if (cutHappened && rules.cutGrantsExtraTurn) extraTurn = true;
    if (newState == TokenState.finished && rules.homeGrantsExtraTurn) extraTurn = true;
    
    // Avoid infinite play if won
    if (hasWon) extraTurn = false;
    
    final int consSixes = (state.diceValue == 6 && extraTurn) ? state.consecutiveSixes + 1 : 0;

    // Handle 3 sixes
    if (consSixes >= 3) {
      if (rules.tripleSixBringsCoinOut) {
         log.add('${currentPlayer.name} rolled 3 sixes! Brining one token out automatically.');
         final homeIndexes = updatedTokens.where((t) => t.isAtHome).map((t) => t.id).toList();
         if (homeIndexes.isNotEmpty) {
           updatedTokens[homeIndexes.first] = updatedTokens[homeIndexes.first].copyWith(
             state: TokenState.active, position: 0
           );
           players[currentPlayer.index] = updatedPlayer.copyWith(tokens: updatedTokens);
         }
      }
      
      if (rules.tripleSixForfeit) {
        log.add('${currentPlayer.name} rolled 3 sixes — turn forfeited! 🚫');
        extraTurn = false;
      }
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
        consecutiveOnes: 0,
        eventLog: _trimLog(log),
        winnerId: winnerId,
      );
    }

    return state.copyWith(
      players: players,
      currentPlayerIndex: _nextActivePlayer(players, currentPlayer.index),
      diceValue: 0,
      hasRolled: false,
      phase: _isGameOver(players) ? GamePhase.finished : GamePhase.rolling,
      movableTokenIds: [],
      consecutiveSixes: 0,
      consecutiveOnes: 0,
      eventLog: _trimLog(log),
      winnerId: winnerId,
    );
  }

  // ── Apply dice roll ────────────────────────────────────────────────────────

  static GameState applyDiceRoll(GameState state, int diceValue) {
    final player = state.currentPlayer;
    final rules = state.customRules;
    List<String> log = List.from(state.eventLog);
    log.add('${player.name} rolled a $diceValue');

    final int consOnes = (diceValue == 1) ? state.consecutiveOnes + 1 : 0;
    final int consSixes = (diceValue == 6) ? state.consecutiveSixes + 1 : 0;
    
    List<Player> players = List.from(state.players);

    // Rule: 3 consecutive 1s
    if (consOnes >= 3) {
      bool skipTurn = false;
      
      if (rules.tripleOneKillsOwn) {
        log.add('💀 ${player.name} rolled 3 ones! Own furthest token is killed.');
        // Kill furthest active token
        final activeTokens = player.activeTokens;
        if (activeTokens.isNotEmpty) {
           activeTokens.sort((a, b) => b.position.compareTo(a.position));
           final furthest = activeTokens.first;
           final updatedTokens = List<Token>.from(player.tokens);
           final idx = updatedTokens.indexWhere((t) => t.id == furthest.id);
           updatedTokens[idx] = furthest.copyWith(state: TokenState.home, position: -1);
           players[player.index] = player.copyWith(tokens: updatedTokens);
        }
      }
      
      if (rules.tripleOneSkipsTurn) skipTurn = true;
      
      if (skipTurn) {
        log.add('${player.name}\'s turn skipped due to 3 ones! 🚫');
        return state.copyWith(
          players: players,
          diceValue: 0, // Reset
          hasRolled: false,
          currentPlayerIndex: _nextActivePlayer(players, player.index),
          phase: GamePhase.rolling,
          movableTokenIds: [],
          consecutiveOnes: 0,
          consecutiveSixes: 0,
          eventLog: _trimLog(log),
        );
      }
    }

    final sWithDice = state.copyWith(
      players: players,
      diceValue: diceValue, 
      consecutiveOnes: consOnes,
      consecutiveSixes: consSixes,
      eventLog: _trimLog(log)
    );

    final movable = getMovableTokens(sWithDice, players[player.index], diceValue);

    if (movable.isEmpty) {
      log.add('${player.name} has no moves — skipped.');
      final next = _nextActivePlayer(players, player.index);
      final s = sWithDice.copyWith(
        hasRolled: true,
        currentPlayerIndex: next,
        phase: GamePhase.rolling,
        movableTokenIds: [],
        consecutiveSixes: 0,
        consecutiveOnes: 0, 
      );
      return s.copyWith(diceValue: 0, hasRolled: false, remainingTurnSeconds: s.turnTimeSeconds);
    }

    // Auto-move if only one token can move
    if (movable.length == 1) {
      final afterRoll = sWithDice.copyWith(
        hasRolled: true,
        phase: GamePhase.moving,
        movableTokenIds: movable,
      );
      return moveToken(afterRoll, movable.first);
    }

    return sWithDice.copyWith(
      hasRolled: true,
      phase: GamePhase.moving,
      movableTokenIds: movable,
    );
  }

  // ── Cuts ───────────────────────────────────────────────────────────────────

  static List<Player> _applyCuts({
    required List<Player> players,
    required int movingPlayerIndex,
    required int newPosition,
    required List<String> log,
    required CustomRules rules,
  }) {
    final updated = List<Player>.from(players);
    final movingAbsPos = (newPosition + BoardPaths.playerStartIndex[movingPlayerIndex]) % 52;

    if (rules.safeZonesEnabled && BoardPaths.safePositions.contains(movingAbsPos)) return players;

    for (int i = 0; i < players.length; i++) {
      if (i == movingPlayerIndex) continue;
      final opponent = players[i];
      final newTokens = opponent.tokens.map((t) {
        if (t.isAtHome || t.isFinished || t.position > 51) return t;
        if (t.state == TokenState.safe) return t; 

        final oppAbsPos = (t.position + BoardPaths.playerStartIndex[i]) % 52;
        if (oppAbsPos == movingAbsPos) {
          log.add('✂️ ${players[movingPlayerIndex].name} cut ${opponent.name}\'s token!');
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

  static List<String> _trimLog(List<String> log) {
    if (log.length > 30) return log.sublist(log.length - 30);
    return log;
  }

  // ── Create initial state ───────────────────────────────────────────────────

  static GameState createInitialState({
    required List<Map<String, dynamic>> playerConfigs,
    String gameMode = GameMode.classic,
    int turnTimerSeconds = AppConstants.defaultTurnSeconds,
    CustomRules customRules = const CustomRules(),
  }) {
    final players = playerConfigs.asMap().entries.map((e) {
      final i = e.key;
      final cfg = e.value;
      return Player(
        index: i,
        name: cfg['name'] as String? ?? BoardPaths.playerColorNames[i],
        type: cfg['type'] as PlayerType? ?? PlayerType.human,
        aiDifficulty: cfg['difficulty'] as String? ?? AIDifficulty.medium,
        tokens: List.generate(
            AppConstants.tokensPerPlayer,
            (j) => Token(id: j, playerIndex: i)),
        avatarEmoji: cfg['avatar'] as String? ?? '🎮',
        hasCut: false,
      );
    }).toList();

    return GameState(
      players: players,
      phase: GamePhase.rolling,
      gameMode: gameMode,
      turnTimeSeconds: turnTimerSeconds,
      remainingTurnSeconds: turnTimerSeconds,
      customRules: customRules,
      consecutiveOnes: 0,
      consecutiveSixes: 0, 
    );
  }
}
