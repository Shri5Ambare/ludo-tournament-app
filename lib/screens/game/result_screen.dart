// lib/screens/game/result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/board_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/share_utils.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> results;
  const ResultScreen({super.key, required this.results});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ConfettiController _confetti;

  List<Map> get _players =>
      (widget.results['players'] as List?)?.cast<Map>() ?? [];
  bool get _isTournamentGame =>
      widget.results['isTournamentGame'] as bool? ?? false;
  bool get _isFinals => widget.results['isFinals'] as bool? ?? false;
  int? get _groupIndex => widget.results['tournamentGroupIndex'] as int?;

  List<Map> get _sorted => [..._players]
    ..sort((a, b) =>
        (a['rank'] as int? ?? 99).compareTo(b['rank'] as int? ?? 99));

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winner = _sorted.isNotEmpty ? _sorted.first : null;
    final winnerName = winner?['name'] as String? ?? 'Unknown';
    final winnerColor =
        BoardPaths.playerColors[winner?['color'] as int? ?? 0];

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -100, right: -50,
            child: CircleAvatar(radius: 150, backgroundColor: winnerColor.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: CircleAvatar(radius: 100, backgroundColor: AppColors.primary.withValues(alpha: 0.05)),
          ),

          // Confetti burst at top
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 50,
              gravity: 0.1,
              emissionFrequency: 0.04,
              colors: const [
                AppColors.redPlayer, AppColors.greenPlayer,
                AppColors.yellowPlayer, AppColors.bluePlayer,
                AppColors.primary, Color(0xFFFFD700),
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Header
                if (_isFinals)
                  Text('TOURNAMENT CHAMPION!',
                      style: GoogleFonts.fredoka(
                          fontSize: 28,
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2))
                      .animate().scale(curve: Curves.elasticOut, duration: 800.ms)
                else if (_isTournamentGame)
                  Text(
                    'GROUP ${String.fromCharCode(64 + (_groupIndex ?? 1))} RESULT',
                    style: GoogleFonts.fredoka(
                        fontSize: 24, color: AppColors.textDark, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ).animate().fadeIn()
                else
                  Text('GAME OVER!',
                      style: GoogleFonts.fredoka(
                          fontSize: 36,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2))
                      .animate().scale(curve: Curves.elasticOut, duration: 800.ms),

                const SizedBox(height: 32),

                // Winner podium
                if (winner != null) _buildWinnerPodium(winnerName, winnerColor),

                const SizedBox(height: 32),

                // Rankings Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('FINAL RANKINGS',
                          style: GoogleFonts.fredoka(
                              fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('${_sorted.length} PLAYERS',
                            style: GoogleFonts.fredoka(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Full rankings list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _sorted.length,
                    itemBuilder: (context, i) {
                      final p = _sorted[i];
                      final rank = p['rank'] as int? ?? (i + 1);
                      final name = p['name'] as String? ?? 'Player';
                      final color =
                          BoardPaths.playerColors[p['color'] as int? ?? 0];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                          border: rank == 1
                              ? Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                             Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.1),
                              ),
                              child: Center(
                                child: Text(_rankEmoji(rank),
                                    style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(name,
                                  style: GoogleFonts.fredoka(
                                      fontSize: 18, 
                                      color: rank == 1 ? AppColors.textDark : AppColors.textDark.withValues(alpha: 0.7),
                                      fontWeight: rank == 1 ? FontWeight.bold : FontWeight.w500)),
                            ),
                            if (rank == 1 && _isTournamentGame)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.greenPlayer.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('ADVANCES →',
                                    style: GoogleFonts.fredoka(
                                        fontSize: 10,
                                        color: AppColors.greenPlayer,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1)),
                              )
                            else
                              Text('#$rank',
                                  style: GoogleFonts.fredoka(
                                      fontSize: 18,
                                      color: rank == 1
                                          ? AppColors.primary
                                          : AppColors.textDark.withValues(alpha: 0.2),
                                      fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                          .animate(delay: (i * 80).ms)
                          .slideX(begin: 0.1)
                          .fadeIn();
                    },
                  ),
                ),

                // Action buttons
                _buildButtons(context, winnerName),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerPodium(String name, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withValues(alpha: 0.3), Colors.transparent],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),
            
            // Podium Card
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
                ],
                border: Border.all(color: color.withValues(alpha: 0.1), width: 8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 48))),
                ),
              ),
            ),
          ],
        ).animate().scale(curve: Curves.elasticOut, duration: 1.seconds),
        const SizedBox(height: 20),
        Text(name.toUpperCase(),
            style: GoogleFonts.fredoka(
                fontSize: 32,
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5))
            .animate(delay: 400.ms)
            .fadeIn()
            .slideY(begin: 0.2),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _isFinals
                ? 'TOURNAMENT CHAMPION! 🎊'
                : _isTournamentGame
                    ? 'GROUP WINNER — ADVANCES!'
                    : 'MATCH WINNER! 🎉',
            style: GoogleFonts.fredoka(fontSize: 12, color: color, fontWeight: FontWeight.bold),
          ),
        ).animate(delay: 500.ms).fadeIn(),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, String winnerName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Share button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _showShareCard(context, winnerName),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.share_outlined, size: 20),
              label: Text('SHARE VICTORY',
                  style: GoogleFonts.fredoka(
                      fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Back to bracket if tournament game
              if (_isTournamentGame)
                Expanded(
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => context.go('/tournament/bracket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text('BACK TO BRACKET',
                          style: GoogleFonts.fredoka(
                              fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: OutlinedButton(
                      onPressed: () => context.go('/home'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.textDark.withValues(alpha: 0.1), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        foregroundColor: AppColors.textDark.withValues(alpha: 0.6),
                      ),
                      child: Text('HOME',
                          style: GoogleFonts.fredoka(
                              fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // Replay: go back to lobby with last config stored in results
                        final extra = widget.results['lastLobbyConfig'];
                        if (extra != null) {
                          context.go('/lobby', extra: extra as Map<String, dynamic>);
                        } else {
                          context.go('/lobby', extra: {'mode': 'quick'});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text('PLAY AGAIN',
                          style: GoogleFonts.fredoka(
                              fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showShareCard(BuildContext context, String winnerName) {
    final entries = _sorted
        .asMap()
        .entries
        .map((e) => ResultEntry(
              rank: e.value['rank'] as int? ?? e.key + 1,
              name: e.value['name'] as String? ?? '',
              isWinner: e.key == 0,
            ))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResultShareCard(
              title: _isFinals
                  ? 'Tournament Champion'
                  : _isTournamentGame
                      ? 'Group Result'
                      : 'Game Result',
              entries: entries,
              subtitle: _isFinals
                  ? '🏆 $winnerName wins the tournament!'
                  : null,
            ),
            const SizedBox(height: 24),
            Container(
               width: double.infinity,
               height: 64,
               decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  // share_plus integration point
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Screenshot and share!',
                        style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ));
                },
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                label: Text('SHARE NOW',
                    style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '🎮';
    }
  }
}
