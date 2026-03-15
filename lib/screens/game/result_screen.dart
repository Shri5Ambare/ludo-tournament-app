// lib/screens/game/result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/board_paths.dart';
import '../../core/theme/app_theme.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> results;
  const ResultScreen({super.key, required this.results});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = (widget.results['players'] as List?)?.cast<Map>() ?? [];
    final sorted = [...players]..sort((a, b) =>
        (a['rank'] as int? ?? 99).compareTo(b['rank'] as int? ?? 99));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: [
                AppColors.redPlayer, AppColors.greenPlayer,
                AppColors.yellowPlayer, AppColors.bluePlayer,
                AppColors.primary, AppColors.accent,
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text('Game Over!',
                    style: GoogleFonts.fredoka(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold))
                    .animate().scale(curve: Curves.elasticOut),

                const SizedBox(height: 8),
                Text('Final Results',
                    style: GoogleFonts.nunito(
                        fontSize: 16, color: AppColors.textMuted)),

                const SizedBox(height: 40),

                // Podium
                if (sorted.length >= 1) ...[
                  _buildPodium(sorted),
                ],

                const SizedBox(height: 32),

                // Full rankings
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) {
                      final p = sorted[i];
                      final rank = p['rank'] as int? ?? (i + 1);
                      final color = BoardPaths.playerColors[p['color'] as int? ?? 0];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.darkCard,
                          border: Border.all(
                              color: rank == 1 ? AppColors.accent : AppColors.darkBorder),
                        ),
                        child: Row(
                          children: [
                            Text(_rankEmoji(rank),
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(p['name'] as String? ?? 'Player',
                                  style: GoogleFonts.fredoka(
                                      fontSize: 18, color: Colors.white)),
                            ),
                            Text('#$rank',
                                style: GoogleFonts.fredoka(
                                    fontSize: 18,
                                    color: rank == 1
                                        ? AppColors.accent
                                        : Colors.white60)),
                          ],
                        ),
                      ).animate(delay: (i * 100).ms).slideX(begin: 0.2).fadeIn();
                    },
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/home'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.darkBorder),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('🏠 Home',
                              style: GoogleFonts.fredoka(
                                  fontSize: 16, color: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go('/home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('🎲 Play Again',
                              style: GoogleFonts.fredoka(
                                  fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map> sorted) {
    if (sorted.isEmpty) return const SizedBox();
    final winner = sorted[0];
    final winnerColor = BoardPaths.playerColors[winner['color'] as int? ?? 0];

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: winnerColor.withOpacity(0.2),
            border: Border.all(color: AppColors.accent, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 4,
              )
            ],
          ),
          child: Center(
            child: Text('🏆', style: const TextStyle(fontSize: 48)),
          ),
        ).animate().scale(curve: Curves.elasticOut, delay: 300.ms),
        const SizedBox(height: 12),
        Text(winner['name'] as String? ?? 'Winner',
            style: GoogleFonts.fredoka(
                fontSize: 28,
                color: AppColors.accent,
                fontWeight: FontWeight.bold))
            .animate(delay: 500.ms).fadeIn().slideY(begin: 0.2),
        Text('Champion! 🎉',
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.white60))
            .animate(delay: 600.ms).fadeIn(),
      ],
    );
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '4️⃣';
    }
  }
}
