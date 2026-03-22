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
      ('🎮', 'GAMES', '47'),
      ('🏆', 'WINS', '28'),
      ('💀', 'LOSSES', '19'),
      ('🔥', 'STREAK', '5'),
      ('⭐', 'LEVEL', '12'),
      ('💰', 'COINS', '2,400'),
    ];

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('PLAYER PROFILE',
            style: GoogleFonts.fredoka(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Avatar Section
            Stack(
              alignment: Alignment.center,
              children: [
                // Glow
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.15), Colors.transparent],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds),
                
                // Avatar Card
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
                    ],
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.05), width: 8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, Color(0xFF7B85FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                          child: Text('🎮', style: TextStyle(fontSize: 52))),
                    ),
                  ),
                ),
              ],
            ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
            
            const SizedBox(height: 24),
            Text('UMESH NEXUS',
                style: GoogleFonts.fredoka(
                    fontSize: 28, color: AppColors.textDark, fontWeight: FontWeight.bold, letterSpacing: 1))
                .animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
            
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('LEVEL 12 • PRO PLAYER',
                  style: GoogleFonts.fredoka(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ).animate(delay: 300.ms).fadeIn(),
            
            const SizedBox(height: 32),
            
            // Stats Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text('STATISTICS',
                  style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 16),
            
            // Stats grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: stats.length,
              itemBuilder: (context, i) {
                final s = stats[i];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.$1, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 8),
                      Text(s.$3,
                          style: GoogleFonts.fredoka(
                              fontSize: 20,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold)),
                      Text(s.$2,
                          style: GoogleFonts.fredoka(
                              fontSize: 9, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ).animate(delay: (400 + (i * 50)).ms).scale().fadeIn();
              },
            ),
            
            const SizedBox(height: 32),
            
            // XP Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text('PROGRESS',
                  style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 16),
            const _XpBar(current: 350, total: 600),
            
            const SizedBox(height: 32),
            
            // Achievements Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ACHIEVEMENTS',
                  style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                '🥇 First Win', '🔥 5x Streak', '🤖 AI Slayer',
                '🏆 Champ', '⚡ Quick Draw', '🎲 Lucky Six',
              ].map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
                ),
                child: Text(a.toUpperCase(),
                    style: GoogleFonts.fredoka(
                        fontSize: 11, color: AppColors.textDark.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
              )).toList(),
            ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RANK PROGRESS',
                  style: GoogleFonts.fredoka(fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
              Text('$current / $total XP',
                  style: GoogleFonts.fredoka(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: current / total,
              backgroundColor: AppColors.lightBg,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 12,
            ),
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn().slideX(begin: 0.1);
  }
}
