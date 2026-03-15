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
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Tournament History',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: tournaments.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tournaments.length,
              itemBuilder: (context, i) {
                return _TournamentHistoryCard(
                  tournament: tournaments[i],
                ).animate(delay: (i * 60).ms).slideY(begin: 0.1).fadeIn();
              },
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('No tournaments yet',
              style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Host your first tournament to see history here',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.darkCard,
        border: Border.all(
          color: isCompleted
              ? AppColors.accent.withOpacity(0.3)
              : AppColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isCompleted ? '🏆' : '⏳',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(tournament.name,
                    style: GoogleFonts.fredoka(
                        fontSize: 18, color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isCompleted
                      ? AppColors.greenPlayer.withOpacity(0.15)
                      : AppColors.accent.withOpacity(0.1),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Incomplete',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: isCompleted
                        ? AppColors.greenPlayer
                        : AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                  icon: '👥',
                  label: '${tournament.playerNames.length} players'),
              _InfoChip(icon: '🎮', label: tournament.gameMode),
              _InfoChip(
                  icon: '⏱️', label: '${tournament.turnTimerSeconds}s timer'),
              if (tournament.championName != null)
                _InfoChip(
                    icon: '🥇', label: 'Winner: ${tournament.championName}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(tournament.createdAt),
            style: GoogleFonts.nunito(
                fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}
