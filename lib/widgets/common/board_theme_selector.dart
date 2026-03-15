// lib/widgets/common/board_theme_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';

class BoardThemeSelector extends ConsumerWidget {
  const BoardThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final themes = [
      _ThemeOption(
        id: BoardThemes.classic,
        label: 'Classic',
        emoji: '🎮',
        colors: [const Color(0xFF1A1035), const Color(0xFF6C3CE1)],
      ),
      _ThemeOption(
        id: BoardThemes.neon,
        label: 'Neon',
        emoji: '💜',
        colors: [const Color(0xFF0D0D0D), const Color(0xFF00FFFF)],
      ),
      _ThemeOption(
        id: BoardThemes.space,
        label: 'Space',
        emoji: '🚀',
        colors: [const Color(0xFF000014), const Color(0xFF4FC3F7)],
      ),
      _ThemeOption(
        id: BoardThemes.forest,
        label: 'Forest',
        emoji: '🌿',
        colors: [const Color(0xFF1B2C1A), const Color(0xFF66BB6A)],
      ),
      _ThemeOption(
        id: BoardThemes.diwali,
        label: 'Diwali',
        emoji: '🪔',
        colors: [const Color(0xFF1A0A00), const Color(0xFFFF9800)],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Board Theme',
            style: GoogleFonts.fredoka(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: themes.length,
            itemBuilder: (context, i) {
              final theme = themes[i];
              final isSelected = settings.boardTheme == theme.id;
              return GestureDetector(
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setBoardTheme(theme.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  width: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: theme.colors,
                    ),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(theme.emoji,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(theme.label,
                          style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: AppColors.accent, size: 14),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThemeOption {
  final String id;
  final String label;
  final String emoji;
  final List<Color> colors;

  const _ThemeOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.colors,
  });
}
