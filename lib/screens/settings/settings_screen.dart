// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/board_theme_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('SETTINGS',
            style: GoogleFonts.fredoka(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        physics: const BouncingScrollPhysics(),
        children: [
          const _SectionHeader(title: 'AUDIO & FEEDBACK'),
          _ToggleTile(
            icon: Icons.volume_up_rounded,
            label: 'SOUND EFFECTS',
            subtitle: 'Action sounds and alerts',
            value: settings.soundEnabled,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleSound(),
          ).animate(delay: 50.ms).fadeIn().slideX(begin: 0.1),
          _ToggleTile(
            icon: Icons.music_note_rounded,
            label: 'BACKGROUND MUSIC',
            subtitle: 'Relaxing game music',
            value: settings.musicEnabled,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleMusic(),
          ).animate(delay: 100.ms).fadeIn().slideX(begin: 0.1),
          _ToggleTile(
            icon: Icons.vibration_rounded,
            label: 'VIBRATION',
            subtitle: 'Haptic feedback on turns',
            value: settings.vibrationEnabled,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleVibration(),
          ).animate(delay: 150.ms).fadeIn().slideX(begin: 0.1),

          const SizedBox(height: 32),
          const _SectionHeader(title: 'VISUALS'),
          _ToggleTile(
            icon: Icons.dark_mode_rounded,
            label: 'DARK MODE',
            subtitle: 'Easier on the eyes',
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
          ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.1),
          const SizedBox(height: 16),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BOARD THEME', style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 16),
                const BoardThemeSelector(),
              ],
            ),
          ).animate(delay: 250.ms).fadeIn().slideX(begin: 0.1),

          const SizedBox(height: 32),
          const _SectionHeader(title: 'GAMEPLAY'),
          _buildCard(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('TURN TIMER', style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                 const SizedBox(height: 16),
                 Row(
                   children: [15, 30, 45, 60].map((secs) {
                     final sel = settings.turnTimerSeconds == secs;
                     return Expanded(
                       child: Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 4),
                         child: GestureDetector(
                           onTap: () => ref.read(settingsProvider.notifier).setTurnTimer(secs),
                           child: AnimatedContainer(
                             duration: 250.ms,
                             padding: const EdgeInsets.symmetric(vertical: 14),
                             decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: sel ? AppColors.primary : AppColors.lightBg,
                                boxShadow: sel ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
                             ),
                             child: Center(
                               child: Text('${secs}s',
                                   style: GoogleFonts.fredoka(
                                       fontSize: 14,
                                       color: sel ? Colors.white : AppColors.textDark.withValues(alpha: 0.4),
                                       fontWeight: FontWeight.bold)),
                             ),
                           ),
                         ),
                       ),
                     );
                   }).toList(),
                 ),
               ],
             ),
          ).animate(delay: 300.ms).fadeIn().slideX(begin: 0.1),

          const SizedBox(height: 32),
          const _SectionHeader(title: 'ABOUT'),
          _buildCard(
            padding: EdgeInsets.zero,
            child: const Column(
              children: [
                _AboutRow(label: 'VERSION', value: '2.0.0 PREMIUM'),
                Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF0F0F0)),
                _AboutRow(label: 'DEVELOPER', value: 'SSIT NEXUS'),
                Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF0F0F0)),
                _AboutRow(label: 'WEBSITE', value: 'SSITNEXUS.COM'),
              ],
            ),
          ).animate(delay: 350.ms).fadeIn().slideX(begin: 0.1),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(24)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(title,
            style: GoogleFonts.fredoka(
                fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.label, required this.subtitle, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
          ],
        ),
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          secondary: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: (value ? AppColors.primary : AppColors.textDark).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: value ? AppColors.primary : AppColors.textDark.withValues(alpha: 0.3), size: 24),
          ),
          title: Text(label, style: GoogleFonts.fredoka(fontSize: 16, color: AppColors.textDark, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          subtitle: Text(subtitle, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
          activeThumbColor: AppColors.primary,
          inactiveTrackColor: AppColors.lightBg,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.fredoka(fontSize: 13, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const Spacer(),
            Text(value, style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
