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
    const themeIds = BoardThemes.all;

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: themeIds.length,
        itemBuilder: (context, i) {
          final td = BoardThemes.get(themeIds[i]);
          final isSelected = settings.boardTheme == td.id;
          final borderColor = td.playerColors.isNotEmpty ? td.playerColors.first : AppColors.primary;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(settingsProvider.notifier).setBoardTheme(td.id);
            },
            child: AnimatedContainer(
              duration: 250.ms,
              margin: const EdgeInsets.only(right: 16),
              width: 86,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.lightBg,
                border: Border.all(
                  color: isSelected ? borderColor : AppColors.textDark.withValues(alpha: 0.05),
                  width: isSelected ? 2.5 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                         BoxShadow(
                          color: borderColor.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                   Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MiniBoardPreview(themeData: td),
                        const SizedBox(height: 8),
                        Text(td.emoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(td.label.toUpperCase(),
                            style: GoogleFonts.fredoka(
                                fontSize: 9,
                                color: isSelected ? AppColors.textDark : AppColors.textDark.withValues(alpha: 0.4),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 6, right: 6,
                      child: Icon(Icons.check_circle_rounded,
                          color: borderColor, size: 16),
                    ),
                ],
              ),
            ),
          ).animate(delay: (i * 50).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
        },
      ),
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
          Paint()..color = cc[i].withValues(alpha: 0.75));
      if (glow) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(1), const Radius.circular(4)),
            Paint()..color = cc[i].withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
    }
    canvas.drawRect(Rect.fromLTWH(w, h, w-1, h-1), Paint()..color = cell);
  }

  @override
  bool shouldRepaint(covariant _MiniPainter old) => old.bg != bg || old.glow != glow;
}
