// lib/widgets/tournament/bracket_tree_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tournament_model.dart';

/// Visual tournament bracket tree painter
class BracketTreeWidget extends StatelessWidget {
  final TournamentState tournament;
  const BracketTreeWidget({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Tournament Bracket',
              style: GoogleFonts.fredoka(
                  fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
        ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group stage column
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _columnHeader('GROUP STAGE', AppColors.primary),
                  const SizedBox(height: 8),
                  ...tournament.groups.map((g) => _GroupNode(group: g)),
                ],
              ),
            ),

            // Connector lines
            SizedBox(
              width: 40,
              child: CustomPaint(
                painter: _ConnectorPainter(
                  groupCount: tournament.groups.length,
                ),
                size: Size(40, tournament.groups.length * 100.0),
              ),
            ),

            // Finals column
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _columnHeader('FINALS', AppColors.accent),
                  const SizedBox(height: 8),
                  if (tournament.currentRound >= 2)
                    ...tournament.roundWinners
                        .map((w) => _WinnerNode(player: w))
                  else
                    ...List.generate(
                      tournament.groups.length,
                      (i) => _PlaceholderNode(label: 'Winner ${String.fromCharCode(65 + i)}'),
                    ),
                  if (tournament.champion != null)
                    _ChampionNode(champion: tournament.champion!),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _columnHeader(String label, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.fredoka(
            fontSize: 12, color: color, letterSpacing: 1),
      ),
    );
  }
}

class _GroupNode extends StatelessWidget {
  final TournamentGroup group;
  const _GroupNode({required this.group});

  @override
  Widget build(BuildContext context) {
    final color = group.isComplete ? AppColors.greenPlayer : AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(group.groupLabel,
                  style: GoogleFonts.fredoka(
                      fontSize: 13, color: color, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (group.isComplete)
                const Text('✅', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ...group.players.map((p) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Text(p.isBot ? '🤖' : '🎮',
                        style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p.name,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: group.winnerName == p.name
                              ? AppColors.accent
                              : Colors.white70,
                          fontWeight: group.winnerName == p.name
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (group.winnerName == p.name)
                      const Text('🏆', style: TextStyle(fontSize: 10)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _WinnerNode extends StatelessWidget {
  final TournamentPlayer player;
  const _WinnerNode({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.accent.withOpacity(0.1),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Text(player.isBot ? '🤖' : '🏆',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(player.name,
                style: GoogleFonts.fredoka(
                    fontSize: 13, color: Colors.white),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderNode extends StatelessWidget {
  final String label;
  const _PlaceholderNode({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.darkCard,
        border: Border.all(
            color: AppColors.darkBorder, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty,
              color: AppColors.textMuted, size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ChampionNode extends StatelessWidget {
  final TournamentPlayer champion;
  const _ChampionNode({required this.champion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.3),
            AppColors.primary.withOpacity(0.2),
          ],
        ),
        border: Border.all(color: AppColors.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text('CHAMPION',
              style: GoogleFonts.fredoka(
                  fontSize: 12, color: AppColors.accent, letterSpacing: 2)),
          Text(champion.name,
              style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Custom painter to draw connector lines between group stage and finals
class _ConnectorPainter extends CustomPainter {
  final int groupCount;
  _ConnectorPainter({required this.groupCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.darkBorder
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (groupCount == 0) return;

    final cellH = size.height / groupCount;

    for (int i = 0; i < groupCount; i++) {
      final y = cellH * i + cellH / 2;
      // Horizontal from group to center
      canvas.drawLine(Offset(0, y), Offset(size.width / 2, y), paint);
    }

    // Vertical line in center
    final firstY = cellH / 2;
    final lastY = cellH * (groupCount - 1) + cellH / 2;
    canvas.drawLine(
        Offset(size.width / 2, firstY), Offset(size.width / 2, lastY), paint);

    // Horizontal to finals
    final midY = (firstY + lastY) / 2;
    canvas.drawLine(
        Offset(size.width / 2, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.groupCount != groupCount;
}
