// lib/utils/share_utils.dart
//
// Utility to share game/tournament result as a styled image card.
// Uses the Share plugin (share_plus) and renders a widget to image.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

/// Builds a shareable result card widget (for screenshot/share)
class ResultShareCard extends StatelessWidget {
  final String title;
  final List<ResultEntry> entries;
  final String? subtitle;

  const ResultShareCard({
    super.key,
    required this.title,
    required this.entries,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1035), Color(0xFF2D1B69)],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 30),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎲', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text('LUDO TOURNAMENT',
                  style: GoogleFonts.fredoka(
                      fontSize: 14,
                      color: AppColors.accent,
                      letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.fredoka(
                  fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: GoogleFonts.nunito(
                    fontSize: 12, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 20),
          const Divider(color: AppColors.darkBorder),
          const SizedBox(height: 12),
          // Entries
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(_rankEmoji(e.rank),
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _rankColor(e.rank),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.name,
                          style: GoogleFonts.fredoka(
                              fontSize: 16, color: Colors.white)),
                    ),
                    if (e.isWinner)
                      const Text('🏆', style: TextStyle(fontSize: 16)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          const Divider(color: AppColors.darkBorder),
          const SizedBox(height: 10),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Play at ',
                  style: GoogleFonts.nunito(
                      fontSize: 11, color: AppColors.textMuted)),
              Text('ssitnexus.com',
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
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

  Color _rankColor(int rank) {
    switch (rank) {
      case 1: return AppColors.accent;
      case 2: return const Color(0xFFBDBDBD);
      case 3: return const Color(0xFFCD7F32);
      default: return AppColors.textMuted;
    }
  }
}

class ResultEntry {
  final int rank;
  final String name;
  final bool isWinner;
  const ResultEntry(
      {required this.rank, required this.name, this.isWinner = false});
}

/// Share result text (fallback when image sharing isn't available)
String buildShareText({
  required String gameName,
  required List<ResultEntry> entries,
}) {
  final buffer = StringBuffer();
  buffer.writeln('🎲 $gameName - Ludo Tournament Results');
  buffer.writeln('─────────────────');
  for (final e in entries) {
    final emoji = e.rank == 1
        ? '🥇'
        : e.rank == 2
            ? '🥈'
            : e.rank == 3
                ? '🥉'
                : '#${e.rank}';
    buffer.writeln('$emoji ${e.name}${e.isWinner ? ' 🏆' : ''}');
  }
  buffer.writeln('─────────────────');
  buffer.writeln('Play Ludo Tournament at ssitnexus.com');
  return buffer.toString();
}
