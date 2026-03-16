// lib/widgets/common/board_theme_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/board_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/board_themes.dart';
import '../../providers/settings_provider.dart';

class BoardThemeSelector extends ConsumerWidget {
  const BoardThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeIds = BoardThemes.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Board Theme',
            style: GoogleFonts.fredoka(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: themeIds.length,
            itemBuilder: (context, i) {
              final td = BoardThemes.get(themeIds[i]);
              final isSelected = settings.boardTheme == td.id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(settingsProvider.notifier).setBoardTheme(td.id);
                },
                child: AnimatedContainer(
                  duration: 220.ms,
                  margin: const EdgeInsets.only(right: 12),
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: td.background,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : Colors.white12,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (td.playerColors.isNotEmpty
                                      ? td.playerColors.first
                                      : AppColors.accent)
                                  .withOpacity(0.4),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MiniBoardPreview(themeData: td),
                      const SizedBox(height: 6),
                      Text(td.emoji,
                          style: const TextStyle(fontSize: 14)),
                      Text(td.label,
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              color: isSelected ? Colors.white : Colors.white54,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.accent, size: 12),
                    ],
                  ),
                ),
              ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.1);
            },
          ),
        ),
      ],
    );
  }
}

class _MiniBoardPreview extends StatelessWidget {
  final BoardThemeData themeData;
  const _MiniBoardPreview({required this.themeData});

  @override
  Widget build(BuildContext context) {
    final colors = themeData.playerColors.isNotEmpty
        ? themeData.playerColors
        : BoardPaths.playerColors;
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: _MiniPainter(
          bg: themeData.background,
          cell: themeData.cellColor,
          colors: colors,
          glow: themeData.glowEffect,
        ),
      ),
    );
  }
}

class _MiniPainter extends CustomPainter {
  final Color bg;
  final Color cell;
  final List<Color> colors;
  final bool glow;
  const _MiniPainter({required this.bg, required this.cell, required this.colors, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 3;
    final h = size.height / 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = bg);
    final corners = [[0,0],[0,2],[2,0],[2,2]];
    final cc = [colors[0], colors[3], colors[1], colors[2]];
    for (int i = 0; i < 4; i++) {
      final rect = Rect.fromLTWH(corners[i][1]*w, corners[i][0]*h, w-1, h-1);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..color = cc[i].withOpacity(0.75));
      if (glow) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(1), const Radius.circular(4)),
            Paint()..color = cc[i].withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
    }
    canvas.drawRect(Rect.fromLTWH(w, h, w-1, h-1), Paint()..color = cell);
  }

  @override
  bool shouldRepaint(covariant _MiniPainter old) => old.bg != bg || old.glow != glow;
}
