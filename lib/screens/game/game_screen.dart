import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shake/shake.dart';
import 'package:ludo_tournament_app/core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../providers/chat_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/board/ludo_board_widget.dart';
import '../../widgets/common/game_chat_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> config;
  const GameScreen({super.key, required this.config});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _navigated = false;
  ShakeDetector? _shakeDetector;
  bool _isShaking = false;

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
            customRules: (widget.config['customRules'] as CustomRules?) ?? const CustomRules(),
            isOnline: widget.config['isOnline'] as bool? ?? false,
            roomId: widget.config['roomId'] as String?,
          );

      // Initialize Shake Detector
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: () => _handleShake(),
        shakeThresholdGravity: 2.7,
      );
    });
  }

  void _handleShake() {
    final gameState = ref.read(gameProvider);
    if (gameState == null) return;
    
    // Only roll if it's our turn and we haven't rolled
    final isOurTurn = !gameState.currentPlayer.isAI && 
                      gameState.currentPlayerIndex == _localPlayerIndex;
    
    if (isOurTurn && !gameState.hasRolled && gameState.phase == GamePhase.rolling && !_isShaking) {
      _isShaking = true;
      HapticFeedback.vibrate();
      
      // Simulate physical "flick" delay
      Future.delayed(400.ms, () {
        if (mounted) {
          HapticFeedback.heavyImpact();
          ref.read(gameProvider.notifier).rollDice();
          setState(() => _isShaking = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
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
          // Pass config so Play Again button works
          'lastLobbyConfig': {'gameMode': widget.config['gameMode'] ?? GameMode.classic},
        });
      });
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Background patterns (subtle)
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: CustomPaint(
                  painter: _BackgroundPatternPainter(),
                ),
              ),
            ),
            // ── Main game column ─────────────────────────────────────
            Column(
              children: [
                _buildTopBar(context, gameState),
                const SizedBox(height: 8),
                // TOP PLAYERS (0 & 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPlayerCorner(_getPlayer(gameState, 0), gameState),
                      _buildPlayerCorner(_getPlayer(gameState, 1), gameState),
                    ],
                  ),
                ),
                // Board
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Center(child: LudoBoardWidget(gameState: gameState)),
                  ),
                ),
                // BOTTOM PLAYERS (3 & 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlayerCorner(_getPlayer(gameState, 3), gameState),
                      _buildPlayerCorner(_getPlayer(gameState, 2), gameState),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Exit button (Rounded Bubble)
          Container(
            height: 44, width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark.withValues(alpha: 0.6), size: 18),
              onPressed: () => _showExitDialog(context),
            ),
          ),
          const Spacer(),
          Text(
            _isTournamentGame
                ? (_isFinals ? '🏆 FINALS' : 'TOURNAMENT')
                : (widget.config['gameMode'] == GameMode.quick ? '⚡ QUICK LUDO' : '🏠 CLASSIC LUDO'),
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          // Settings (Round Bubble)
          Container(
             width: 44, height: 44,
             decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
             ),
             child: Icon(Icons.settings_rounded, color: AppColors.textDark.withValues(alpha: 0.6), size: 22),
          ),
        ],
      ),
    );
  }

  Player? _getPlayer(GameState state, int index) {
    try {
      return state.players.firstWhere((p) => p.index == index);
    } catch (_) {
      return null;
    }
  }

  Widget _buildPlayerCorner(Player? player, GameState gameState) {
    if (player == null) return const SizedBox(width: 140, height: 50);

    final isCurrent = player.index == gameState.currentPlayerIndex;
    final color = player.color;

    return Container(
      width: 140,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isCurrent ? color.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
            blurRadius: isCurrent ? 12 : 6,
            offset: const Offset(0, 4),
            spreadRadius: isCurrent ? 1 : 0,
          ),
        ],
        border: Border.all(
          color: isCurrent ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background "Bubble" gradient if current
          if (isCurrent)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.25)],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // Avatar Circle
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Center(
                    child: Text(player.avatarEmoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? color : AppColors.textDark,
                    ),
                  ),
                ),
                if (isCurrent)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildSmallDice(gameState, color),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate(target: isCurrent ? 1 : 0).scale(
      begin: const Offset(1, 1), end: const Offset(1.05, 1.05),
      duration: 300.ms, curve: Curves.easeOutBack,
    );
  }

  Widget _buildSmallDice(GameState state, Color playerColor) {
    if (state.phase == GamePhase.rolling) {
       return Container(
         width: 12, height: 12,
         decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
       ).animate(onPlay: (c) => c.repeat()).scale(duration: 500.ms);
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomBar(BuildContext context, GameState gameState) {
    final currentPlayer = gameState.currentPlayer;
    final canRoll = !currentPlayer.isAI &&
        !gameState.isFinished &&
        !gameState.hasRolled &&
        gameState.phase == GamePhase.rolling;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Game Log Bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
            ),
            child: Text(
              gameState.eventLog.isNotEmpty ? gameState.eventLog.last : 'Game started! Have fun!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textDark.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Big 3D Dice Button
          GestureDetector(
             onTap: canRoll ? () {
                HapticFeedback.heavyImpact();
                ref.read(gameProvider.notifier).rollDice();
             } : null,
             child: Column(
               children: [
                 _Big3DDice(
                   value: gameState.diceValue,
                   color: currentPlayer.color,
                   isRolling: gameState.phase == GamePhase.rolling && gameState.isAIExecuting, // Simplified
                 ),
                 const SizedBox(height: 8),
                 Text(
                   canRoll ? 'TAP TO ROLL' : (gameState.phase == GamePhase.moving ? 'CHOOSE TOKEN' : 'PLEASE WAIT...'),
                   style: GoogleFonts.fredoka(
                     fontSize: 14,
                     fontWeight: FontWeight.bold,
                     color: AppColors.textDark.withValues(alpha: 0.4),
                     letterSpacing: 1.2,
                   ),
                 ),
               ],
             ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Exit Game?',
            style: GoogleFonts.fredoka(color: AppColors.textDark, fontSize: 22)),
        content: Text(
          _isTournamentGame
              ? 'This group will be marked as incomplete.'
              : 'Your progress will be lost.',
          style: GoogleFonts.nunito(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Stay',
                style: GoogleFonts.nunito(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameProvider.notifier).resetGame();
              if (_isTournamentGame) {
                context.go('/tournament/bracket');
              } else {
                context.go('/home');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: Text('Exit',
                style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Background Pattern Painter ──────────────────────────────────────────────

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 2;
    final r = Random(42);
    for (int i = 0; i < 20; i++) {
       final x = r.nextDouble() * size.width;
       final y = r.nextDouble() * size.height;
       final s = r.nextDouble() * 40 + 20;
       if (r.nextBool()) {
         canvas.drawCircle(Offset(x, y), s/2, paint);
       } else {
         canvas.drawRect(Rect.fromLTWH(x, y, s, s), paint);
       }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Big 3D Dice Placeholder Widget ──────────────────────────────────────────

class _Big3DDice extends StatelessWidget {
  final int value;
  final Color color;
  final bool isRolling;

  const _Big3DDice({required this.value, required this.color, required this.isRolling});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: AppColors.redPlayer, // Large red dice as in Image 1
        borderRadius: BorderRadius.circular(20),
        gradient: const RadialGradient(
          colors: [Color(0xFFFF8B8B), Color(0xFFE53935)],
          center: Alignment(-0.2, -0.2),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Center(
        child: _buildDiceDots(value),
      ),
    ).animate(target: isRolling ? 1 : 0).shake(duration: 500.ms).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), curve: Curves.elasticOut);
  }

  Widget _buildDiceDots(int val) {
    if (val == 0) return const SizedBox.shrink();
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(9, (index) {
        final List<int> activeIndices;
        switch(val) {
          case 1: activeIndices = [4]; break;
          case 2: activeIndices = [0, 8]; break;
          case 3: activeIndices = [0, 4, 8]; break;
          case 4: activeIndices = [0, 2, 6, 8]; break;
          case 5: activeIndices = [0, 2, 4, 6, 8]; break;
          case 6: activeIndices = [0, 2, 3, 5, 6, 8]; break;
          default: activeIndices = [];
        }
        if (activeIndices.contains(index)) {
           return Container(
             margin: const EdgeInsets.all(4),
             decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
           );
        }
        return const SizedBox.shrink();
      }),
    );
  }
}

// ── Timer ring widget (Playful Redesign) ──────────────────────────────────────────────────────

class _TimerRing extends StatefulWidget {
  final int seconds;
  final int total;
  const _TimerRing({required this.seconds, required this.total});

  @override
  State<_TimerRing> createState() => _TimerRingState();
}

class _TimerRingState extends State<_TimerRing> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final frac = (widget.total > 0 ? widget.seconds / widget.total : 1.0).clamp(0.0, 1.0);
    return Container(
      width: 44, height: 44,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: frac,
            strokeWidth: 4,
            backgroundColor: AppColors.lightBorder,
            valueColor: AlwaysStoppedAnimation(frac > 0.3 ? AppColors.success : AppColors.error),
          ),
          Text('${widget.seconds}', style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
