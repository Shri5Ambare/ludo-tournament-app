// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1035), AppColors.darkBg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildMenuGrid(context)),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LUDO', style: GoogleFonts.fredoka(
                fontSize: 36, fontWeight: FontWeight.bold,
                color: Colors.white, letterSpacing: 4,
              )),
              Text('TOURNAMENT', style: GoogleFonts.fredoka(
                fontSize: 14, color: AppColors.accent, letterSpacing: 3,
              )),
            ],
          ).animate().slideX(begin: -0.3).fadeIn(),
          Row(
            children: [
              _iconBtn(context, Icons.person_rounded, () => context.push('/profile')),
              const SizedBox(width: 8),
              _iconBtn(context, Icons.settings_rounded, () => context.push('/settings')),
            ],
          ).animate().slideX(begin: 0.3).fadeIn(),
        ],
      ),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menuItems = [
      _MenuItem('Quick Play', '⚡', AppColors.accent,
          'vs Computer or pass & play', () => _goToLobby(context, 'quick')),
      _MenuItem('Local Multiplayer', '👥', AppColors.greenPlayer,
          '2–4 players, one device', () => _goToLobby(context, 'local')),
      _MenuItem('🏆 Tournament', '🏆', AppColors.primary,
          '5–16 players bracket mode', () => context.push('/tournament/setup'),
          isFeature: true),
      _MenuItem('vs Computer', '🤖', AppColors.redPlayer,
          'Easy / Medium / Hard AI', () => _goToLobby(context, 'ai')),
      _MenuItem('Leaderboard', '📊', const Color(0xFF00BCD4),
          'Global rankings', () {}),
      _MenuItem('Achievements', '🎖️', const Color(0xFFFF5722),
          'Your badges & rewards', () {}),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          return menuItems[index]
              .buildCard(context)
              .animate(delay: (index * 80).ms)
              .slideY(begin: 0.3)
              .fadeIn();
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'SSiT Nexus • Building Tomorrow\'s Technology Today',
        style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMuted),
      ),
    );
  }

  void _goToLobby(BuildContext context, String mode) {
    context.push('/lobby', extra: {'mode': mode});
  }
}

class _MenuItem {
  final String title;
  final String emoji;
  final Color color;
  final String subtitle;
  final VoidCallback onTap;
  final bool isFeature;

  const _MenuItem(
      this.title, this.emoji, this.color, this.subtitle, this.onTap,
      {this.isFeature = false});

  Widget buildCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(isFeature ? 0.35 : 0.18),
              color.withOpacity(isFeature ? 0.15 : 0.06),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(isFeature ? 0.7 : 0.3),
            width: isFeature ? 1.5 : 1,
          ),
          boxShadow: isFeature
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 16)]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(subtitle,
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: Colors.white60),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
