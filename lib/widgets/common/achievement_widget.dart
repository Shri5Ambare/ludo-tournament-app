// lib/widgets/common/achievement_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class Achievement {
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;
  final int progress;
  final int total;

  const Achievement({
    required this.emoji,
    required this.title,
    required this.description,
    this.unlocked = false,
    this.progress = 0,
    this.total = 1,
  });
}

class AchievementsGrid extends StatelessWidget {
  final List<Achievement> achievements;
  const AchievementsGrid({super.key, required this.achievements});

  static List<Achievement> defaults() => [
        const Achievement(emoji: '🎲', title: 'First Roll', description: 'Play your first game', unlocked: true, progress: 1, total: 1),
        const Achievement(emoji: '✂️', title: 'First Cut', description: 'Cut an opponent token', unlocked: true, progress: 1, total: 1),
        const Achievement(emoji: '🏠', title: 'Homecoming', description: 'Get all 4 tokens home', unlocked: false, progress: 2, total: 4),
        const Achievement(emoji: '🏆', title: 'Champion', description: 'Win your first game', unlocked: false, progress: 0, total: 1),
        const Achievement(emoji: '🤖', title: 'Bot Buster', description: 'Beat AI on Hard', unlocked: false, progress: 0, total: 1),
        const Achievement(emoji: '🔥', title: 'On Fire', description: '5 win streak', unlocked: false, progress: 1, total: 5),
        const Achievement(emoji: '⚡', title: 'Speed Demon', description: 'Win a Quick mode game', unlocked: false, progress: 0, total: 1),
        const Achievement(emoji: '🏟️', title: 'Tournament King', description: 'Win a tournament', unlocked: false, progress: 0, total: 1),
        const Achievement(emoji: '💯', title: 'Century', description: 'Play 100 games', unlocked: false, progress: 0, total: 100),
        const Achievement(emoji: '📡', title: 'LAN Lord', description: 'Host a hotspot game', unlocked: false, progress: 0, total: 1),
        const Achievement(emoji: '🎯', title: 'Strategist', description: 'Cut 50 opponent tokens', unlocked: false, progress: 0, total: 50),
        const Achievement(emoji: '👑', title: 'Ludo King', description: 'Reach Level 50', unlocked: false, progress: 1, total: 50),
      ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, i) => _AchievementCard(achievement: achievements[i]),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: unlocked
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.darkCard,
          border: Border.all(
            color: unlocked
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.darkBorder,
            width: unlocked ? 1.5 : 1,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji with lock overlay
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  achievement.emoji,
                  style: TextStyle(
                    fontSize: 32,
                    color: unlocked ? null : Colors.white24,
                  ),
                ),
                if (!unlocked)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black38,
                      border: Border.all(
                          color: AppColors.darkBorder, width: 1.5),
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: Colors.white38, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              achievement.title,
              style: GoogleFonts.fredoka(
                fontSize: 12,
                color: unlocked ? Colors.white : Colors.white38,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Progress bar
            if (!unlocked && achievement.total > 1) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: achievement.progress / achievement.total,
                    minHeight: 3,
                    backgroundColor: AppColors.darkBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                  ),
                ),
              ),
              Text(
                '${achievement.progress}/${achievement.total}',
                style: GoogleFonts.nunito(
                    fontSize: 9, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(achievement.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(achievement.title,
                style: GoogleFonts.fredoka(
                    fontSize: 22, color: Colors.white)),
            const SizedBox(height: 4),
            Text(achievement.description,
                style: GoogleFonts.nunito(
                    fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: achievement.unlocked
                    ? AppColors.greenPlayer.withOpacity(0.2)
                    : AppColors.darkCard,
              ),
              child: Text(
                achievement.unlocked ? '✅ Unlocked!' : '🔒 Locked',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: achievement.unlocked
                      ? AppColors.greenPlayer
                      : Colors.white54,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: GoogleFonts.nunito(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
