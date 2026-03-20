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
        backgroundColor: Colors.transparent,
        title: Text('Settings',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: '🔊 Audio'),
          _ToggleTile(
            icon: Icons.volume_up_rounded,
            label: 'Sound Effects',
            subtitle: 'Dice rolls, token moves, cuts',
            value: settings.soundEnabled,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleSound(),
          ).animate(delay: 50.ms).fadeIn(),
          _ToggleTile(
            icon: Icons.music_note_rounded,
            label: 'Background Music',
            subtitle: 'In-game music',
            value: settings.musicEnabled,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleMusic(),
          ).animate(delay: 100.ms).fadeIn(),
          _ToggleTile(
            icon: Icons.vibration_rounded,
            label: 'Vibration',
            subtitle: 'Haptic feedback',
            value: settings.vibrationEnabled,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleVibration(),
          ).animate(delay: 150.ms).fadeIn(),

          const SizedBox(height: 24),
          _SectionHeader(title: '🎨 Appearance'),
          _ToggleTile(
            icon: Icons.dark_mode_rounded,
            label: 'Dark Mode',
            subtitle: 'Toggle dark/light theme',
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 16),
          const BoardThemeSelector().animate(delay: 250.ms).fadeIn(),

          const SizedBox(height: 24),
          _SectionHeader(title: '⏱️ Turn Timer'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [15, 30, 45].map((secs) {
                final sel = settings.turnTimerSeconds == secs;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => ref.read(settingsProvider.notifier).setTurnTimer(secs),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: sel ? AppColors.accent.withValues(alpha: 0.15) : AppColors.darkBg,
                        border: Border.all(color: sel ? AppColors.accent : AppColors.darkBorder),
                      ),
                      child: Text('${secs}s',
                          style: GoogleFonts.fredoka(
                              fontSize: 16,
                              color: sel ? AppColors.accent : Colors.white60)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ).animate(delay: 300.ms).fadeIn(),

          const SizedBox(height: 24),
          _SectionHeader(title: 'ℹ️ About'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              children: [
                _AboutRow(label: 'Version', value: '1.0.0'),
                const Divider(color: AppColors.darkBorder, height: 20),
                _AboutRow(label: 'Developer', value: 'SSiT Nexus'),
                const Divider(color: AppColors.darkBorder, height: 20),
                _AboutRow(label: 'Website', value: 'ssitnexus.com'),
                const Divider(color: AppColors.darkBorder, height: 20),
                _AboutRow(label: 'Framework', value: 'Flutter 3.x'),
              ],
            ),
          ).animate(delay: 350.ms).fadeIn(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: GoogleFonts.fredoka(
                fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: SwitchListTile(
          secondary: Icon(icon, color: value ? AppColors.primary : AppColors.textMuted),
          title: Text(label, style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white)),
          subtitle: Text(subtitle, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMuted)),
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted)),
          const Spacer(),
          Text(value, style: GoogleFonts.nunito(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      );
}
