// lib/widgets/board/ludo_board_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/board_paths.dart';

import '../../core/theme/board_themes.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';

class LudoBoardWidget extends ConsumerWidget {
  final GameState gameState;
  const LudoBoardWidget({super.key, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeData = BoardThemes.get(settings.boardTheme);

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / 15;
          return Stack(
            children: [
              // Board background
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: LudoBoardPainter(theme: themeData),
              ),
              // Tokens
              ..._buildTokens(constraints, cellSize, ref),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildTokens(
      BoxConstraints constraints, double cellSize, WidgetRef ref) {
    final tokens = <Widget>[];

    for (final player in gameState.players) {
      for (final token in player.tokens) {
        final cell = token.boardCell;
        final row = cell[0];
        final col = cell[1];

        // Stack multiple tokens at same position with offset
        final sameCell = _tokensAtCell(cell);
        final offsetIdx = sameCell.indexWhere(
            (t) => t.id == token.id && t.playerIndex == token.playerIndex);

        final offsets = [
          const Offset(0, 0), const Offset(6, 0),
          const Offset(0, 6), const Offset(6, 6),
        ];
        final offset = offsets[offsetIdx.clamp(0, 3)];

        final isMovable = gameState.movableTokenIds.contains(token.id) &&
            player.index == gameState.currentPlayerIndex;

        final left = col * cellSize + offset.dx;
        final top = row * cellSize + offset.dy;
        final tokenSize = cellSize * 0.75;

        tokens.add(
          Positioned(
            left: left + (cellSize - tokenSize) / 2,
            top: top + (cellSize - tokenSize) / 2,
            child: GestureDetector(
              onTap: isMovable
                  ? () => ref.read(gameProvider.notifier).selectToken(token.id)
                  : null,
              child: _TokenWidget(
                playerIndex: player.index,
                tokenId: token.id,
                size: tokenSize,
                isMovable: isMovable,
                isFinished: token.isFinished,
                themeColors: BoardThemes.get(
                  ref.watch(settingsProvider).boardTheme,
                ).playerColors,
              ),
            ),
          ),
        );
      }
    }
    return tokens;
  }

  List<Token> _tokensAtCell(List<int> cell) {
    final result = <Token>[];
    for (final player in gameState.players) {
      for (final token in player.tokens) {
        final c = token.boardCell;
        if (c[0] == cell[0] && c[1] == cell[1]) result.add(token);
      }
    }
    return result;
  }
}

// ─────────────────────────────────────────────
// Token Widget  (animated)
// ─────────────────────────────────────────────

class _TokenWidget extends StatefulWidget {
  final int playerIndex;
  final int tokenId;
  final double size;
  final bool isMovable;
  final bool isFinished;
  final List<Color> themeColors;

  const _TokenWidget({
    required this.playerIndex,
    required this.tokenId,
    required this.size,
    required this.isMovable,
    required this.isFinished,
    required this.themeColors,
  });

  @override
  State<_TokenWidget> createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<_TokenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _rotate;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _rotate = Tween(begin: 0.0, end: 2 * 3.14159).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _glow = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 14.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: 4.0), weight: 50),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_TokenWidget old) {
    super.didUpdateWidget(old);
    // Bounce when token becomes movable
    if (!old.isMovable && widget.isMovable) {
      _ctrl.forward(from: 0).then((_) => _ctrl.reverse());
    }
    // Spin when just finished (reached home)
    if (!old.isFinished && widget.isFinished) {
      _ctrl.repeat(reverse: false);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _ctrl.stop();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.themeColors.isNotEmpty &&
            widget.playerIndex < widget.themeColors.length
        ? widget.themeColors[widget.playerIndex]
        : BoardPaths.playerColors[widget.playerIndex];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Transform.scale(
          scale: widget.isMovable ? _scale.value : 1.0,
          child: Transform.rotate(
            angle: widget.isFinished ? _rotate.value : 0.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isFinished
                    ? color.withValues(alpha: 0.9)
                    : color,
                border: Border.all(
                  color: widget.isMovable
                      ? Colors.white
                      : color.withValues(alpha: 0.6),
                  width: widget.isMovable ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isMovable
                        ? Colors.white.withValues(alpha: 0.6)
                        : widget.isFinished
                            ? color.withValues(alpha: 0.7)
                            : color.withValues(alpha: 0.3),
                    blurRadius: widget.isMovable
                        ? _glow.value
                        : widget.isFinished
                            ? 10
                            : 4,
                    spreadRadius: widget.isMovable ? 2 : 0,
                  ),
                ],
              ),
              child: Center(
                child: widget.isFinished
                    ? Icon(Icons.star_rounded,
                        color: Colors.white, size: widget.size * 0.5)
                    : Text(
                        '${widget.tokenId + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.size * 0.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────
// Board Painter - draws the complete Ludo board
// ─────────────────────────────────────────────

class LudoBoardPainter extends CustomPainter {
  final BoardThemeData theme;
  const LudoBoardPainter({required this.theme});

  List<Color> get _playerColors => theme.playerColors.isNotEmpty
      ? theme.playerColors
      : BoardPaths.playerColors;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / 15;
    final cellH = size.height / 15;

    _drawBackground(canvas, size);
    _drawHomeYards(canvas, cellW, cellH);
    _drawMainPath(canvas, cellW, cellH);
    _drawHomeColumns(canvas, cellW, cellH);
    _drawCenter(canvas, cellW, cellH, size);
    _drawGrid(canvas, size, cellW, cellH);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = theme.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawHomeYards(Canvas canvas, double cw, double ch) {
    final colors = _playerColors;

    final rects = [
      Rect.fromLTWH(0, 0, cw * 6, ch * 6),
      Rect.fromLTWH(cw * 9, 0, cw * 6, ch * 6),
      Rect.fromLTWH(cw * 9, ch * 9, cw * 6, ch * 6),
      Rect.fromLTWH(0, ch * 9, cw * 6, ch * 6),
    ];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()..color = colors[i].withValues(alpha: 0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rects[i].deflate(2), const Radius.circular(8)),
        paint,
      );
      final borderPaint = Paint()
        ..color = colors[i].withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rects[i].deflate(2), const Radius.circular(8)),
        borderPaint,
      );
      final innerPaint = Paint()..color = theme.yardOverlay;
      final innerRect = rects[i].deflate(cw * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, const Radius.circular(6)),
        innerPaint,
      );

      // Token circles
      final yards = BoardPaths.homeYards[i]!;
      for (final pos in yards) {
        final cx = pos[1] * cw + cw / 2;
        final cy = pos[0] * ch + ch / 2;
        final r = cw * 0.35;
        final circlePaint = Paint()..color = colors[i].withValues(alpha: 0.3);
        canvas.drawCircle(Offset(cx, cy), r, circlePaint);
        // Neon glow ring
        if (theme.glowEffect) {
          final glowPaint = Paint()
            ..color = colors[i].withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(Offset(cx, cy), r + 4, glowPaint);
        }
        final circleStroke = Paint()
          ..color = colors[i].withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(cx, cy), r, circleStroke);
      }
    }
  }

  void _drawMainPath(Canvas canvas, double cw, double ch) {
    final cellPaint = Paint()..color = theme.cellColor;
    final safePaint = Paint()..color = theme.safeCellColor;
    final borderPaint = Paint()
      ..color = theme.gridLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < BoardPaths.mainPath.length; i++) {
      final cell = BoardPaths.mainPath[i];
      final rect = Rect.fromLTWH(
        cell[1] * cw + 0.5, cell[0] * ch + 0.5, cw - 1, ch - 1,
      );
      final isSafe = BoardPaths.safePositions.contains(i);
      canvas.drawRect(rect, isSafe ? safePaint : cellPaint);
      canvas.drawRect(rect, borderPaint);

      if (isSafe && i != 0) {
        // Glow on safe cells for neon/diwali
        if (theme.glowEffect) {
          final glowPaint = Paint()
            ..color = theme.safeCellColor.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawRect(rect, glowPaint);
        }
        _drawStar(canvas, rect.center, cw * 0.25,
            Colors.white.withValues(alpha: theme.glowEffect ? 0.55 : 0.3));
      }
    }

    // Player start positions
    for (int p = 0; p < 4; p++) {
      final startIdx = BoardPaths.playerStartIndex[p];
      final cell = BoardPaths.mainPath[startIdx];
      final rect = Rect.fromLTWH(
        cell[1] * cw + 0.5, cell[0] * ch + 0.5, cw - 1, ch - 1,
      );
      final paint = Paint()..color = _playerColors[p].withValues(alpha: 0.5);
      canvas.drawRect(rect, paint);
    }
  }

  void _drawHomeColumns(Canvas canvas, double cw, double ch) {
    final colors = _playerColors;
    for (int p = 0; p < 4; p++) {
      final cells = BoardPaths.homeColumns[p]!;
      for (int i = 0; i < cells.length; i++) {
        final cell = cells[i];
        final rect = Rect.fromLTWH(
          cell[1] * cw + 0.5, cell[0] * ch + 0.5, cw - 1, ch - 1,
        );
        final paint = Paint()
          ..color = colors[p].withValues(alpha: 0.2 + i * 0.05);
        canvas.drawRect(rect, paint);
        final borderPaint = Paint()
          ..color = colors[p].withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  void _drawCenter(Canvas canvas, double cw, double ch, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final halfW = cw * 3;
    final halfH = ch * 3;
    final colors = _playerColors;

    // Center background
    final bgPaint = Paint()..color = theme.centerBg;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: halfW * 2, height: halfH * 2),
      bgPaint,
    );

    final triangles = [
      [Offset(cx - halfW, cy - halfH), Offset(cx + halfW, cy - halfH), Offset(cx, cy)],
      [Offset(cx + halfW, cy - halfH), Offset(cx + halfW, cy + halfH), Offset(cx, cy)],
      [Offset(cx + halfW, cy + halfH), Offset(cx - halfW, cy + halfH), Offset(cx, cy)],
      [Offset(cx - halfW, cy + halfH), Offset(cx - halfW, cy - halfH), Offset(cx, cy)],
    ];

    for (int i = 0; i < 4; i++) {
      final path = Path()
        ..moveTo(triangles[i][0].dx, triangles[i][0].dy)
        ..lineTo(triangles[i][1].dx, triangles[i][1].dy)
        ..lineTo(triangles[i][2].dx, triangles[i][2].dy)
        ..close();
      final paint = Paint()..color = colors[i].withValues(alpha: 0.35);
      canvas.drawPath(path, paint);
      if (theme.glowEffect) {
        final glowPaint = Paint()
          ..color = colors[i].withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawPath(path, glowPaint);
      }
    }

    _drawStar(canvas, Offset(cx, cy), cw * 0.8,
        Colors.white.withValues(alpha: theme.glowEffect ? 0.7 : 0.5));
  }

  void _drawGrid(Canvas canvas, Size size, double cw, double ch) {
    final paint = Paint()
      ..color = theme.gridLine
      ..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += cw) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += ch) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi) / 5 - pi / 2;
      final x = center.dx + radius * _cos(angle);
      final y = center.dy + radius * _sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double r) {
    r = r % (2 * pi);
    double result = 1, term = 1;
    for (int i = 1; i <= 10; i++) { term *= -r * r / ((2*i-1) * (2*i)); result += term; }
    return result;
  }

  double _sin(double r) {
    r = r % (2 * pi);
    double result = r, term = r;
    for (int i = 1; i <= 10; i++) { term *= -r * r / ((2*i) * (2*i+1)); result += term; }
    return result;
  }

  @override
  bool shouldRepaint(covariant LudoBoardPainter old) => old.theme.id != theme.id;
}
