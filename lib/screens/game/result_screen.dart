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
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Confetti burst at top
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              gravity: 0.2,
              emissionFrequency: 0.05,
              colors: const [
                AppColors.redPlayer, AppColors.greenPlayer,
                AppColors.yellowPlayer, AppColors.bluePlayer,
                AppColors.primary, AppColors.accent,
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Header
                if (_isFinals)
                  Text('🏆 Tournament Champion!',
                      style: GoogleFonts.fredoka(
                          fontSize: 26,
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold))
                      .animate().scale(curve: Curves.elasticOut)
                else if (_isTournamentGame)
                  Text(
                    'Group ${String.fromCharCode(65 + (_groupIndex ?? 0))} Result',
                    style: GoogleFonts.fredoka(
                        fontSize: 24, color: Colors.white),
                  ).animate().fadeIn()
                else
                  Text('Game Over! 🎉',
                      style: GoogleFonts.fredoka(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold))
                      .animate().scale(curve: Curves.elasticOut),

                const SizedBox(height: 24),

                // Winner podium
                if (winner != null) _buildWinnerPodium(winnerName, winnerColor),

                const SizedBox(height: 24),

                // Full rankings list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _sorted.length,
                    itemBuilder: (context, i) {
                      final p = _sorted[i];
                      final rank = p['rank'] as int? ?? (i + 1);
                      final name = p['name'] as String? ?? 'Player';
                      final color =
                          BoardPaths.playerColors[p['color'] as int? ?? 0];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: rank == 1
                              ? AppColors.accent.withValues(alpha: 0.1)
                              : AppColors.darkCard,
                          border: Border.all(
                            color: rank == 1
                                ? AppColors.accent.withValues(alpha: 0.5)
                                : AppColors.darkBorder,
                            width: rank == 1 ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(_rankEmoji(rank),
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(name,
                                  style: GoogleFonts.fredoka(
                                      fontSize: 18, color: Colors.white)),
                            ),
                            if (rank == 1 && _isTournamentGame)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Advances →',
                                    style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold)),
                              )
                            else
                              Text('#$rank',
                                  style: GoogleFonts.fredoka(
                                      fontSize: 18,
                                      color: rank == 1
                                          ? AppColors.accent
                                          : Colors.white38)),
                          ],
                        ),
                      )
                          .animate(delay: (i * 80).ms)
                          .slideX(begin: 0.2)
                          .fadeIn();
                    },
                  ),
                ),

                // Action buttons
                _buildButtons(context, winnerName),
                const SizedBox(height: 12),
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
                border: Border.all(color: color, width: 4),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 32,
                      spreadRadius: 6),
                ],
              ),
            ),
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 40))),
            ),
          ],
        ).animate().scale(curve: Curves.elasticOut, delay: 200.ms),
        const SizedBox(height: 12),
        Text(name,
            style: GoogleFonts.fredoka(
                fontSize: 26,
                color: AppColors.accent,
                fontWeight: FontWeight.bold))
            .animate(delay: 400.ms)
            .fadeIn()
            .slideY(begin: 0.2),
        Text(
          _isFinals
              ? 'Tournament Champion! 🎊'
              : _isTournamentGame
                  ? 'Group Winner — advances to Finals!'
                  : 'Winner! 🎉',
          style: GoogleFonts.nunito(fontSize: 13, color: Colors.white60),
        ).animate(delay: 500.ms).fadeIn(),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, String winnerName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Share button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showShareCard(context, winnerName),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.darkBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Text('📤', style: TextStyle(fontSize: 16)),
              label: Text('Share Result',
                  style: GoogleFonts.fredoka(
                      fontSize: 15, color: Colors.white70)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Back to bracket if tournament game
              if (_isTournamentGame)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/tournament/bracket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('🏆 Back to Bracket',
                        style: GoogleFonts.fredoka(
                            fontSize: 15, color: Colors.black)),
                  ),
                )
              else ...[
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
                            fontSize: 15, color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
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
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('🎲 Play Again',
                        style: GoogleFonts.fredoka(
                            fontSize: 15, color: Colors.white)),
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // share_plus integration point
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Screenshot and share!',
                      style: GoogleFonts.nunito(color: Colors.white)),
                  backgroundColor: AppColors.darkCard,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              },
              icon: const Icon(Icons.share_rounded),
              label: Text('Share',
                  style: GoogleFonts.fredoka(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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
