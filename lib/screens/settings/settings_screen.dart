// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';

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
          _Section(title: 'Audio', children: [
            _ToggleTile(
              icon: Icons.volume_up_rounded,
              label: 'Sound Effects',
              value: settings.soundEnabled,
              onToggle: () => ref.read(settingsProvider.notifier).toggleSound(),
            ),
            _ToggleTile(
              icon: Icons.music_note_rounded,
              label: 'Background Music',
              value: settings.musicEnabled,
              onToggle: () => ref.read(settingsProvider.notifier).toggleMusic(),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: 'Haptics', children: [
            _ToggleTile(
              icon: Icons.vibration_rounded,
              label: 'Vibration',
              value: settings.vibrationEnabled,
              onToggle: () => ref.read(settingsProvider.notifier).toggleVibration(),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: 'Appearance', children: [
            _ToggleTile(
              icon: Icons.dark_mode_rounded,
              label: 'Dark Mode',
              value: themeMode == ThemeMode.dark,
              onToggle: () => ref.read(themeModeProvider.notifier).toggle(),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: 'Board Theme', children: [
            _BoardThemeSelector(
              current: settings.boardTheme,
              onSelect: (t) => ref.read(settingsProvider.notifier).setBoardTheme(t),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: 'About', children: [
            _InfoTile(label: 'Version', value: '1.0.0'),
            _InfoTile(label: 'Developer', value: 'SSiT Nexus'),
            _InfoTile(label: 'Website', value: 'ssitnexus.com'),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.fredoka(
                fontSize: 17, color: AppColors.textMuted))
            .animate().fadeIn(),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.darkCard,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(children: children),
        ).animate().slideY(begin: 0.1).fadeIn(),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final VoidCallback onToggle;
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: value ? AppColors.primary : Colors.white38),
      title: Text(label,
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 15)),
      trailing: Switch(
        value: value,
        onChanged: (_) => onToggle(),
        activeColor: AppColors.primary,
      ),
    );
  }
}

class _BoardThemeSelector extends StatelessWidget {
  final String current;
  final Function(String) onSelect;
  const _BoardThemeSelector({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final themes = [
      ('classic', '♟️', 'Classic'),
      ('neon', '💜', 'Neon'),
      ('space', '🚀', 'Space'),
      ('forest', '🌿', 'Forest'),
      ('diwali', '🪔', 'Diwali'),
    ];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: themes.map((t) {
          final sel = current == t.$1;
          return GestureDetector(
            onTap: () => onSelect(t.$1),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: sel ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                border: Border.all(
                    color: sel ? AppColors.primary : AppColors.darkBorder),
              ),
              child: Text('${t.$2} ${t.$3}',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: sel ? Colors.white : Colors.white60,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label,
          style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14)),
      trailing: Text(value,
          style: GoogleFonts.nunito(
              color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }
}
