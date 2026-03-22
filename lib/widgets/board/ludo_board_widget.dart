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
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.8),
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                  center: const Alignment(-0.3,-0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 4),
                    blurRadius: 6,
                  ),
                  if (widget.isMovable)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: _glow.value,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Stack(
                children: [
                   // Shining gloss
                   Positioned(
                     left: widget.size * 0.2, top: widget.size *0.15,
                     child: Container(
                       width: widget.size*0.35, height: widget.size*0.2,
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(10),
                         color: Colors.white.withValues(alpha: 0.4),
                       ),
                     ),
                   ),
                   Center(
                    child: widget.isFinished
                        ? Icon(Icons.star_rounded,
                            color: Colors.white, size: widget.size * 0.5)
                        : Text(
                            '${widget.tokenId + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.size * 0.4,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
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
      final rRect = RRect.fromRectAndRadius(rects[i], Radius.circular(cw * 1.5));
      // Outer colored square
      canvas.drawRRect(rRect, Paint()..color = colors[i].withValues(alpha: 0.15));
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = colors[i].withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // Inner white rounded rect
      final innerRect = rects[i].deflate(cw * 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, Radius.circular(cw * 1.0)),
        Paint()..color = theme.centerBg, // Usually near-white
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, Radius.circular(cw * 0.6)),
        Paint()
          ..color = theme.gridLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Token circles
      final yards = BoardPaths.homeYards[i]!;
      for (final pos in yards) {
        final cx = pos[1] * cw + cw / 2;
        final cy = pos[0] * ch + ch / 2;
        final r = cw * 0.45;
        
        canvas.drawCircle(Offset(cx, cy), r, Paint()..color = colors[i]);
        canvas.drawCircle(
          Offset(cx, cy),
          r,
          Paint()
            ..color = theme.gridLine
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  void _drawMainPath(Canvas canvas, double cw, double ch) {
    final cellPaint = Paint()..color = theme.cellColor;
    final safePaint = Paint()..color = theme.safeCellColor;
    final borderPaint = Paint()
      ..color = theme.gridLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < BoardPaths.mainPath.length; i++) {
      final cell = BoardPaths.mainPath[i];
      final rect = Rect.fromLTWH(
        cell[1] * cw + 1.5, cell[0] * ch + 1.5, cw - 3, ch - 3,
      );
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      final isSafe = BoardPaths.safePositions.contains(i);
      
      canvas.drawRRect(rRect, Paint()..color = isSafe ? safePaint.color : cellPaint.color);
      canvas.drawRRect(rRect, borderPaint);

      // Only draw stars strictly on [8, 21, 34, 47]
      if ([8, 21, 34, 47].contains(i)) {
         if (theme.glowEffect) {
           _drawStar(canvas, rect.center, cw * 0.45,
               BoardPaths.playerColors[i~/13].withValues(alpha: 0.5), glow: true);
         }
        _drawStar(canvas, rect.center, cw * 0.35,
            BoardPaths.playerColors[i~/13]);
      }
    }

    // Player start positions drawn fully solid matching the base color
    for (int p = 0; p < 4; p++) {
      final startIdx = BoardPaths.playerStartIndex[p];
      final cell = BoardPaths.mainPath[startIdx];
      final rect = Rect.fromLTWH(
        cell[1] * cw + 0.5, cell[0] * ch + 0.5, cw - 1, ch - 1,
      );
      canvas.drawRect(rect, Paint()..color = _playerColors[p]);
      canvas.drawRect(rect, borderPaint);
    }
  }

  void _drawHomeColumns(Canvas canvas, double cw, double ch) {
    final colors = _playerColors;
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int p = 0; p < 4; p++) {
      final cells = BoardPaths.homeColumns[p]!;
      for (int i = 0; i < cells.length; i++) {
        final cell = cells[i];
        final rect = Rect.fromLTWH(
          cell[1] * cw + 1.5, cell[0] * ch + 1.5, cw - 3, ch - 3,
        );
        final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
        canvas.drawRRect(rRect, Paint()..color = colors[p].withValues(alpha: 0.1));
        canvas.drawRRect(rRect, borderPaint);
      }
    }
  }

  void _drawCenter(Canvas canvas, double cw, double ch, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final halfW = cw * 1.5;
    final halfH = ch * 1.5;
    final colors = _playerColors;

    final triangles = [
      [Offset(cx - halfW, cy - halfH), Offset(cx + halfW, cy - halfH), Offset(cx, cy)],
      [Offset(cx + halfW, cy - halfH), Offset(cx + halfW, cy + halfH), Offset(cx, cy)],
      [Offset(cx + halfW, cy + halfH), Offset(cx - halfW, cy + halfH), Offset(cx, cy)],
      [Offset(cx - halfW, cy + halfH), Offset(cx - halfW, cy - halfH), Offset(cx, cy)],
    ];

    final triangleIndices = [3, 0, 1, 2];

    for (int i = 0; i < 4; i++) {
      final tOffsets = triangles[triangleIndices[i]];
      final path = Path()
        ..moveTo(tOffsets[0].dx, tOffsets[0].dy)
        ..lineTo(tOffsets[1].dx, tOffsets[1].dy)
        ..lineTo(tOffsets[2].dx, tOffsets[2].dy)
        ..close();
      
      canvas.drawPath(path, Paint()..color = colors[i]);
      canvas.drawPath(
        path,
        Paint()
          ..color = theme.gridLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
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

  void _drawStar(Canvas canvas, Offset center, double radius, Color color, {bool glow = false}) {
    final paint = Paint()..color = color;
    if (glow) {
       paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    }
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi) / 5 - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LudoBoardPainter old) => old.theme.id != theme.id;
}
