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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _buildFloatingFooter(context),
        ),
      ),
      body: Stack(
        children: [
          // Background abstract Shapes
          Positioned(
            top: -100, left: -100,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle)),
          ),
          Positioned(
            bottom: -50, right: -50,
            child: Container(width: 200, height: 200, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle)),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                   child: SingleChildScrollView(
                     physics: const BouncingScrollPhysics(),
                     padding: const EdgeInsets.symmetric(horizontal: 20),
                     child: Column(
                       children: [
                         _buildHeroSection(context),
                         const SizedBox(height: 24),
                         _buildMenuGrid(context),
                         const SizedBox(height: 24),
                       ],
                     ),
                   ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                 child: const Icon(Icons.casino_rounded, color: Colors.white, size: 24),
               ),
               const SizedBox(width: 12),
               Text('Ludo Club', style: GoogleFonts.fredoka(
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
               )),
             ],
          ).animate().fadeIn().slideX(begin: -0.2),
          Row(
            children: [
              _iconBtn(context, Icons.notifications_none_rounded, null),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).cardColor, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                  ),
                  child: const Center(child: Text('👨‍💼', style: TextStyle(fontSize: 20))),
                ),
              ),
            ],
          ).animate().fadeIn().slideX(begin: 0.2),
        ],
      ),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, String? route) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: IconButton(
        icon: Icon(icon, color: Theme.of(context).iconTheme.color, size: 22),
        onPressed: route != null ? () => context.push(route) : null,
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
           colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready for a match?', style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Play & Win\nChampionship!', style: GoogleFonts.fredoka(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.push('/tournament/setup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                   child: Text('START NOW', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                ),
              ],
            ),
          ),
          Container(
             width: 100, height: 100,
             decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
             child: const Center(child: Text('🏆', style: TextStyle(fontSize: 60))),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 2000.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menuItems = [
      _MenuItem('Classic Mode', '🎲', AppColors.primary, 'Standard Ludo fun', () => _goToLobby(context, 'local')),
      _MenuItem('Quick Match', '⚡', AppColors.accent, 'Fast-paced game', () => _goToLobby(context, 'quick')),
      _MenuItem('Tournament', '🏆', AppColors.info, 'Championship mode', () => context.push('/tournament/setup'), isFeature: true),
      _MenuItem('vs Computer', '🤖', AppColors.error, 'Offline practice', () => _goToLobby(context, 'ai')),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        return menuItems[index]
            .buildCard(context)
            .animate(delay: (index * 100).ms)
            .slideY(begin: 0.2, curve: Curves.easeOutBack)
            .fadeIn();
      },
    );
  }

  Widget _buildFloatingFooter(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _footerNavBtn(context, Icons.home_rounded, 'Home', true, () {}),
          _footerNavBtn(context, Icons.emoji_events_rounded, 'Leader', false, () => context.push('/leaderboard')),
          _footerNavBtn(context, Icons.people_rounded, 'Social', false, () => context.push('/friends')),
          _footerNavBtn(context, Icons.shopping_bag_rounded, 'Shop', false, () => context.push('/shop')),
          _footerNavBtn(context, Icons.settings_rounded, 'Settings', false, () => context.push('/settings')),
        ],
      ),
    );
  }

  Widget _footerNavBtn(BuildContext context, IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? AppColors.primary : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.4), size: 26),
          const SizedBox(height: 4),
          if (isActive) Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
        ],
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
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.nunito(
                            fontSize: 11, color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
