// lib/screens/game/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/game_models.dart';
import '../../providers/chat_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/board/ludo_board_widget.dart';
import '../../widgets/common/event_log_widget.dart';
import '../../widgets/common/game_chat_widget.dart';
import '../../widgets/dice/dice_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> config;
  const GameScreen({super.key, required this.config});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _navigated = false;

  // Chat — local player info derived from config
  String get _localPlayerName =>
      (widget.config['localPlayerName'] as String?) ??
      (widget.config['playerConfigs'] != null
          ? (widget.config['playerConfigs'] as List).first['name'] as String? ?? 'Player 1'
          : 'Player 1');
  int get _localPlayerIndex =>
      (widget.config['localPlayerIndex'] as int?) ?? 0;

  // Tournament context from config
  int? get _tournamentGroupIndex =>
      widget.config['tournamentGroupIndex'] as int?;
  bool get _isFinals => widget.config['isFinals'] as bool? ?? false;
  bool get _isTournamentGame =>
      _tournamentGroupIndex != null || _isFinals;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear chat from any previous game
      ref.read(chatProvider.notifier).clear();

      // Start background music
      ref.read(audioServiceProvider).startBgMusic();

      // Fix: playerConfigs key was inconsistent across callers — support both keys
      final configs = (widget.config['playerConfigs'] ??
              widget.config['players']) as List?;
      final playerConfigs = configs
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [
            {'name': 'Player 1', 'type': PlayerType.human, 'avatar': '🧑'},
            {'name': 'Bot 1', 'type': PlayerType.ai, 'avatar': '🤖'},
          ];

      ref.read(gameProvider.notifier).initGame(
            playerConfigs: playerConfigs,
            gameMode: widget.config['gameMode'] as String? ?? GameMode.classic,
            turnTimerSeconds:
                widget.config['turnTimerSeconds'] as int? ?? 30,
          );
    });
  }

  @override
  void dispose() {
    ref.read(audioServiceProvider).stopBgMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    if (gameState == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ── Navigate to result when finished (only once) ──
    if (gameState.isFinished && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ranked = gameState.rankedPlayers;
        final winnerName = ranked.isNotEmpty ? ranked.first.name : '';

        // If part of a tournament, notify provider before going to result
        if (_isTournamentGame) {
          final t = ref.read(tournamentProvider);
          if (t != null && winnerName.isNotEmpty) {
            if (_isFinals) {
              ref
                  .read(tournamentProvider.notifier)
                  .completeFinals(winnerName);
            } else if (_tournamentGroupIndex != null) {
              ref
                  .read(tournamentProvider.notifier)
                  .completeGroupGame(_tournamentGroupIndex!, winnerName);
            }
          }
        }

        context.pushReplacement('/result', extra: {
          'players': ranked
              .map((p) => {'name': p.name, 'rank': p.rank, 'color': p.index})
              .toList(),
          'isTournamentGame': _isTournamentGame,
          'tournamentGroupIndex': _tournamentGroupIndex,
          'isFinals': _isFinals,
        });
      });
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main game column ─────────────────────────────────────
            Column(
              children: [
                _buildTopBar(context, gameState),
                _buildPlayerStrip(gameState),
                const SizedBox(height: 4),
                // Event log
                if (gameState.eventLog.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: EventLogWidget(events: gameState.eventLog),
                  ),
                const SizedBox(height: 4),
                // Board
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: LudoBoardWidget(gameState: gameState),
                  ),
                ),
                _buildBottomBar(context, gameState),
              ],
            ),
            // ── Chat panel (slide-up overlay) ────────────────────────
            Consumer(builder: (context, ref, _) {
              final isOpen = ref.watch(chatProvider).isOpen;
              if (!isOpen) return const SizedBox.shrink();
              return Positioned(
                bottom: 0, left: 0, right: 0,
                child: GameChatPanel(
                  localPlayerName: _localPlayerName,
                  localPlayerIndex: _localPlayerIndex,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, GameState gameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Exit button
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
            onPressed: () => _showExitDialog(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // Tournament badge
          if (_isTournamentGame)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                _isFinals
                    ? '🏆 Finals'
                    : 'Group ${String.fromCharCode(65 + (_tournamentGroupIndex ?? 0))}',
                style: GoogleFonts.fredoka(
                    fontSize: 13, color: AppColors.accent),
              ),
            )
          else
            Text(
              gameState.gameMode == GameMode.quick ? '⚡ QUICK' : '🎮 CLASSIC',
              style: GoogleFonts.fredoka(
                  fontSize: 14, color: AppColors.accent, letterSpacing: 1),
            ),
          const Spacer(),
          // Chat FAB (only in multiplayer modes)
          const ChatFab(),
          const SizedBox(width: 8),
          // Turn timer
          _TimerRing(
            seconds: gameState.remainingTurnSeconds,
            total: gameState.turnTimeSeconds,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStrip(GameState gameState) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: gameState.players.length,
        itemBuilder: (context, i) {
          final player = gameState.players[i];
          final isCurrent = i == gameState.currentPlayerIndex;
          return AnimatedContainer(
            duration: 250.ms,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isCurrent
                  ? player.color.withValues(alpha: 0.2)
                  : AppColors.darkCard,
              border: Border.all(
                color: isCurrent ? player.color : AppColors.darkBorder,
                width: isCurrent ? 2 : 1,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                          color: player.color.withValues(alpha: 0.3),
                          blurRadius: 8)
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(player.avatarEmoji,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    Row(
                      children: List.generate(4, (t) {
                        final tok = player.tokens[t];
                        return Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tok.isFinished
                                ? player.color
                                : tok.isAtHome
                                    ? Colors.white12
                                    : player.color.withValues(alpha: 0.55),
                            border: Border.all(
                                color: player.color.withValues(alpha: 0.4),
                                width: 0.5),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                if (player.hasWon) ...[
                  const SizedBox(width: 6),
                  Text('🏅',
                      style: TextStyle(
                          fontSize: 14,
                          color: player.rank == 1
                              ? AppColors.accent
                              : Colors.white54)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, GameState gameState) {
    final currentPlayer = gameState.currentPlayer;
    final isHumanTurn = !currentPlayer.isAI && !gameState.isFinished;
    final canRoll = isHumanTurn &&
        !gameState.hasRolled &&
        gameState.phase == GamePhase.rolling;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        border: Border(
            top: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentPlayer.isAI
                      ? '🤖 ${currentPlayer.name} thinking...'
                      : gameState.phase == GamePhase.moving
                          ? '👆 Tap a token to move'
                          : '🎲 ${currentPlayer.name}\'s turn',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: currentPlayer.color,
                  ),
                ),
                if (gameState.diceValue > 0 && gameState.phase == GamePhase.moving)
                  Text(
                    'Rolled a ${gameState.diceValue}${gameState.movableTokenIds.length > 1 ? " — choose token" : ""}',
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),

          // Dice
          DiceWidget(
            value: gameState.diceValue,
            canRoll: canRoll,
            onRoll: () {
              HapticFeedback.mediumImpact();
              ref.read(gameProvider.notifier).rollDice();
            },
            playerColor: currentPlayer.color,
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Exit Game?',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22)),
        content: Text(
          _isTournamentGame
              ? 'This group will be marked as incomplete.'
              : 'Your progress will be lost.',
          style: GoogleFonts.nunito(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Stay',
                style: GoogleFonts.nunito(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameProvider.notifier).resetGame();
              if (_isTournamentGame) {
                // Return to bracket
                context.go('/tournament/bracket',);
              } else {
                context.go('/home');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: Text('Exit',
                style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Timer ring widget ──────────────────────────────────────────────────────

class _TimerRing extends StatelessWidget {
  final int seconds;
  final int total;
  const _TimerRing({required this.seconds, required this.total});

  @override
  Widget build(BuildContext context) {
    final frac = (total > 0 ? seconds / total : 1.0).clamp(0.0, 1.0);
    final color = frac > 0.5
        ? AppColors.greenPlayer
        : frac > 0.25
            ? AppColors.yellowPlayer
            : AppColors.redPlayer;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: frac,
            strokeWidth: 3,
            backgroundColor: AppColors.darkCard,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text('$seconds',
              style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
