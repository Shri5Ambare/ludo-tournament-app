// lib/widgets/common/player_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/board_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_models.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final bool isCurrentTurn;
  final int remainingSeconds;
  final int totalSeconds;

  const PlayerCard({
    super.key,
    required this.player,
    this.isCurrentTurn = false,
    this.remainingSeconds = 30,
    this.totalSeconds = 30,
  });

  @override
  Widget build(BuildContext context) {
    final color = BoardPaths.playerColors[player.index];
    final finishedCount = player.finishedTokenCount;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentTurn ? color.withOpacity(0.15) : AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentTurn ? color : AppColors.darkBorder,
          width: isCurrentTurn ? 2 : 1,
        ),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + name
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.3),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    player.avatarEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  player.name,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: isCurrentTurn
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (player.isAI)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('AI',
                      style: GoogleFonts.nunito(
                          fontSize: 9, color: AppColors.info)),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Token dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final isHome = i < player.homeTokens.length;
              final isDone = i >= (4 - finishedCount);
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? color
                      : isHome
                          ? color.withOpacity(0.2)
                          : color.withOpacity(0.6),
                  border: Border.all(color: color, width: 1),
                ),
              );
            }),
          ),

          // Turn timer
          if (isCurrentTurn) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: remainingSeconds / totalSeconds,
                minHeight: 3,
                backgroundColor: AppColors.darkBorder,
                valueColor: AlwaysStoppedAnimation<Color>(
                  remainingSeconds <= 5 ? AppColors.error : color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${remainingSeconds}s',
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: remainingSeconds <= 5 ? AppColors.error : AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
