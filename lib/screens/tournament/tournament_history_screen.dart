// lib/screens/tournament/tournament_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tournament_model.dart';

class TournamentHistoryScreen extends StatelessWidget {
  const TournamentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<TournamentModel>('tournaments');
    final tournaments = box.values.toList().reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('TOURNAMENT HISTORY',
            style: GoogleFonts.fredoka(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: tournaments.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              physics: const BouncingScrollPhysics(),
              itemCount: tournaments.length,
              itemBuilder: (context, i) {
                return _TournamentHistoryCard(
                  tournament: tournaments[i],
                ).animate(delay: (i * 100).ms).slideY(begin: 0.1, curve: Curves.easeOutQuad).fadeIn();
              },
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: const Text('🏆', style: TextStyle(fontSize: 64)),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds),
          const SizedBox(height: 32),
          Text('NO TOURNAMENTS YET',
              style: GoogleFonts.fredoka(fontSize: 20, color: AppColors.textDark, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text('Host your first tournament and start your journey towards greatness!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                    fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _TournamentHistoryCard extends StatelessWidget {
  final TournamentModel tournament;
  const _TournamentHistoryCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final isCompleted = tournament.status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
        ],
        border: Border.all(
          color: isCompleted
              ? AppColors.greenPlayer.withValues(alpha: 0.1)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.greenPlayer.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(isCompleted ? '🏆' : '⏳',
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tournament.name,
                        style: GoogleFonts.fredoka(
                            fontSize: 18, color: AppColors.textDark, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(tournament.createdAt).toUpperCase(),
                      style: GoogleFonts.fredoka(
                          fontSize: 10, color: AppColors.textDark.withValues(alpha: 0.3), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isCompleted
                      ? AppColors.greenPlayer.withValues(alpha: 0.1)
                      : AppColors.accent.withValues(alpha: 0.1),
                ),
                child: Text(
                  isCompleted ? 'COMPLETED' : 'PENDING',
                  style: GoogleFonts.fredoka(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isCompleted
                        ? AppColors.greenPlayer
                        : AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                  icon: '👥',
                  label: '${tournament.playerNames.length} PLAYERS'),
              _InfoChip(icon: '🎮', label: tournament.gameMode.toUpperCase()),
              _InfoChip(
                  icon: '⏱️', label: '${tournament.turnTimerSeconds}S TIMER'),
              if (tournament.championName != null)
                _InfoChip(
                    icon: '🥇', label: 'WINNER: ${tournament.championName!.toUpperCase()}'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.fredoka(
                  fontSize: 10, color: AppColors.textDark.withValues(alpha: 0.6), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
