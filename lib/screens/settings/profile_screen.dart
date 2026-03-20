// lib/screens/settings/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Demo profile data
    final stats = [
      ('🎮', 'Games Played', '47'),
      ('🏆', 'Wins', '28'),
      ('💀', 'Losses', '19'),
      ('🔥', 'Win Streak', '5'),
      ('⭐', 'Level', '12'),
      ('💰', 'Coins', '2,400'),
      ('🏅', 'Tournaments Won', '3'),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Profile',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: const Center(
                  child: Text('🎮', style: TextStyle(fontSize: 52))),
            )
                .animate()
                .scale(curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text('Umesh Nexus',
                style: GoogleFonts.fredoka(
                    fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold))
                .animate(delay: 200.ms).fadeIn(),
            Text('Level 12 • SSiT Nexus',
                style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMuted))
                .animate(delay: 300.ms).fadeIn(),
            const SizedBox(height: 8),
            // XP Bar
            const _XpBar(current: 350, total: 600),
            const SizedBox(height: 32),
            // Stats grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: stats.length,
              itemBuilder: (context, i) {
                final s = stats[i];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.darkCard,
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.$1, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(s.$3,
                          style: GoogleFonts.fredoka(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(s.$2,
                          style: GoogleFonts.nunito(
                              fontSize: 10, color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                          maxLines: 2),
                    ],
                  ),
                ).animate(delay: (i * 50).ms).scale().fadeIn();
              },
            ),
            const SizedBox(height: 24),
            // Achievements
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Achievements',
                  style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                '🥇 First Win', '🔥 5x Streak', '🤖 AI Slayer',
                '🏆 Tournament Champ', '⚡ Quick Draw', '🎲 Lucky Six',
              ].map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Text(a,
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: Colors.white70)),
              )).toList(),
            ).animate(delay: 400.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  final int current;
  final int total;
  const _XpBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('XP: $current / $total',
                style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMuted)),
            Text('${(current / total * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: current / total,
            backgroundColor: AppColors.darkCard,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
