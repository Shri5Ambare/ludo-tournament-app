// lib/screens/game/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../widgets/board/ludo_board_widget.dart';
import '../../widgets/dice/dice_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> config;
  const GameScreen({super.key, required this.config});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final configs = widget.config['playerConfigs'] as List<Map<String, dynamic>>?
          ?? [{'name': 'Player 1', 'type': PlayerType.human},
              {'name': 'Bot 1', 'type': PlayerType.ai}];
      ref.read(gameProvider.notifier).initGame(
        playerConfigs: configs,
        gameMode: widget.config['gameMode'] as String? ?? GameMode.classic,
        turnTimerSeconds: widget.config['turnTimerSeconds'] as int? ?? 30,
      );
    });
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

    // Navigate to result when game is over
    if (gameState.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement('/result', extra: {
            'players': gameState.rankedPlayers
                .map((p) => {'name': p.name, 'rank': p.rank, 'color': p.index})
                .toList(),
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, gameState),
            _buildPlayerInfo(gameState),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LudoBoardWidget(gameState: gameState),
              ),
            ),
            _buildBottomBar(context, gameState),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, GameState gameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => _showExitDialog(context),
          ),
          Text(
            gameState.gameMode.toUpperCase(),
            style: GoogleFonts.fredoka(
              fontSize: 16,
              color: AppColors.accent,
              letterSpacing: 2,
            ),
          ),
          // Timer display
          _TimerWidget(
            seconds: gameState.remainingTurnSeconds,
            total: gameState.turnTimeSeconds,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(GameState gameState) {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: gameState.players.length,
        itemBuilder: (context, i) {
          final player = gameState.players[i];
          final isCurrent = i == gameState.currentPlayerIndex;
          return AnimatedContainer(
            duration: 300.ms,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isCurrent
                  ? player.color.withOpacity(0.25)
                  : AppColors.darkCard,
              border: Border.all(
                color: isCurrent ? player.color : AppColors.darkBorder,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(player.avatarEmoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name,
                        style: GoogleFonts.fredoka(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    Row(
                      children: List.generate(
                        4,
                        (t) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: player.tokens[t].isFinished
                                ? player.color
                                : player.tokens[t].isAtHome
                                    ? Colors.white24
                                    : player.color.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, GameState gameState) {
    final currentPlayer = gameState.currentPlayer;
    final isHumanTurn = !currentPlayer.isAI;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                isHumanTurn
                    ? '${currentPlayer.name}\'s Turn'
                    : '${currentPlayer.name} is thinking...',
                style: GoogleFonts.fredoka(
                  fontSize: 15,
                  color: currentPlayer.color,
                ),
              ),
              const SizedBox(height: 12),
              DiceWidget(
                value: gameState.diceValue,
                canRoll: isHumanTurn && !gameState.hasRolled &&
                    gameState.phase == GamePhase.rolling,
                onRoll: () => ref.read(gameProvider.notifier).rollDice(),
                playerColor: currentPlayer.color,
              ),
            ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Exit Game?',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22)),
        content: Text('Your progress will be lost.',
            style: GoogleFonts.nunito(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Stay', style: GoogleFonts.nunito(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameProvider.notifier).resetGame();
              context.go('/home');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Exit', style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TimerWidget extends StatelessWidget {
  final int seconds;
  final int total;
  const _TimerWidget({required this.seconds, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = seconds / total;
    final color = fraction > 0.5
        ? AppColors.greenPlayer
        : fraction > 0.25
            ? AppColors.yellowPlayer
            : AppColors.redPlayer;

    return Container(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.darkCard,
            valueColor: AlwaysStoppedAnimation(color),
            strokeWidth: 3,
          ),
          Text(
            '$seconds',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
