// lib/widgets/board/ludo_board_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/board_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';

class LudoBoardWidget extends ConsumerWidget {
  final GameState gameState;
  const LudoBoardWidget({super.key, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                painter: LudoBoardPainter(),
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
// Token Widget
// ─────────────────────────────────────────────

class _TokenWidget extends StatelessWidget {
  final int playerIndex;
  final int tokenId;
  final double size;
  final bool isMovable;
  final bool isFinished;

  const _TokenWidget({
    required this.playerIndex,
    required this.tokenId,
    required this.size,
    required this.isMovable,
    required this.isFinished,
  });

  @override
  Widget build(BuildContext context) {
    final color = BoardPaths.playerColors[playerIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: isMovable ? Colors.white : color.withOpacity(0.6),
          width: isMovable ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isMovable ? Colors.white.withOpacity(0.5) : color.withOpacity(0.3),
            blurRadius: isMovable ? 8 : 4,
            spreadRadius: isMovable ? 2 : 0,
          ),
        ],
      ),
      child: Center(
        child: isFinished
            ? const Icon(Icons.star, color: Colors.white, size: 14)
            : Text(
                '${tokenId + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Board Painter - draws the complete Ludo board
// ─────────────────────────────────────────────

class LudoBoardPainter extends CustomPainter {
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
    final paint = Paint()..color = const Color(0xFF1E1245);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawHomeYards(Canvas canvas, double cw, double ch) {
    final colors = [
      BoardPaths.playerColors[0], // Red - top-left
      BoardPaths.playerColors[1], // Green - top-right
      BoardPaths.playerColors[2], // Yellow - bottom-right
      BoardPaths.playerColors[3], // Blue - bottom-left
    ];

    final rects = [
      Rect.fromLTWH(0, 0, cw * 6, ch * 6),         // Red
      Rect.fromLTWH(cw * 9, 0, cw * 6, ch * 6),     // Green
      Rect.fromLTWH(cw * 9, ch * 9, cw * 6, ch * 6), // Yellow
      Rect.fromLTWH(0, ch * 9, cw * 6, ch * 6),     // Blue
    ];

    for (int i = 0; i < 4; i++) {
      // Outer yard
      final paint = Paint()..color = colors[i].withOpacity(0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rects[i].deflate(2), const Radius.circular(8)),
        paint,
      );

      // Inner yard border
      final borderPaint = Paint()
        ..color = colors[i].withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rects[i].deflate(2), const Radius.circular(8)),
        borderPaint,
      );

      // Inner white box
      final innerPaint = Paint()..color = Colors.white.withOpacity(0.08);
      final innerRect = rects[i].deflate(cw * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, const Radius.circular(6)),
        innerPaint,
      );

      // Token circles (4 circles in each yard)
      final yards = BoardPaths.homeYards[i]!;
      for (final pos in yards) {
        final cx = pos[1] * cw + cw / 2;
        final cy = pos[0] * ch + ch / 2;
        final r = cw * 0.35;
        // Circle bg
        final circlePaint = Paint()..color = colors[i].withOpacity(0.3);
        canvas.drawCircle(Offset(cx, cy), r, circlePaint);
        final circleStroke = Paint()
          ..color = colors[i].withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(cx, cy), r, circleStroke);
      }
    }
  }

  void _drawMainPath(Canvas canvas, double cw, double ch) {
    final cellPaint = Paint()..color = const Color(0xFF2A1F55);
    final safePaint = Paint()..color = const Color(0xFF1A3A2A);
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < BoardPaths.mainPath.length; i++) {
      final cell = BoardPaths.mainPath[i];
      final rect = Rect.fromLTWH(
        cell[1] * cw + 0.5, cell[0] * ch + 0.5,
        cw - 1, ch - 1,
      );
      final isSafe = BoardPaths.safePositions.contains(i);
      canvas.drawRect(rect, isSafe ? safePaint : cellPaint);
      canvas.drawRect(rect, borderPaint);

      // Draw star on safe positions
      if (isSafe && i != 0) {
        _drawStar(canvas, rect.center, cw * 0.25, Colors.white.withOpacity(0.3));
      }
    }

    // Draw player start positions (colored cells)
    for (int p = 0; p < 4; p++) {
      final startIdx = BoardPaths.playerStartIndex[p];
      final cell = BoardPaths.mainPath[startIdx];
      final rect = Rect.fromLTWH(
        cell[1] * cw + 0.5, cell[0] * ch + 0.5, cw - 1, ch - 1,
      );
      final paint = Paint()..color = BoardPaths.playerColors[p].withOpacity(0.5);
      canvas.drawRect(rect, paint);
    }
  }

  void _drawHomeColumns(Canvas canvas, double cw, double ch) {
    final colors = BoardPaths.playerColors;
    for (int p = 0; p < 4; p++) {
      final cells = BoardPaths.homeColumns[p]!;
      for (int i = 0; i < cells.length; i++) {
        final cell = cells[i];
        final rect = Rect.fromLTWH(
          cell[1] * cw + 0.5, cell[0] * ch + 0.5, cw - 1, ch - 1,
        );
        final paint = Paint()
          ..color = colors[p].withOpacity(0.2 + i * 0.05);
        canvas.drawRect(rect, paint);
        final borderPaint = Paint()
          ..color = colors[p].withOpacity(0.5)
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

    // Draw 4 colored triangles pointing to center
    final colors = BoardPaths.playerColors;
    final triangles = [
      // Top triangle (Green)
      [Offset(cx - halfW, cy - halfH), Offset(cx + halfW, cy - halfH), Offset(cx, cy)],
      // Right triangle (Yellow)
      [Offset(cx + halfW, cy - halfH), Offset(cx + halfW, cy + halfH), Offset(cx, cy)],
      // Bottom triangle (Blue)
      [Offset(cx + halfW, cy + halfH), Offset(cx - halfW, cy + halfH), Offset(cx, cy)],
      // Left triangle (Red)
      [Offset(cx - halfW, cy + halfH), Offset(cx - halfW, cy - halfH), Offset(cx, cy)],
    ];

    for (int i = 0; i < 4; i++) {
      final path = Path()
        ..moveTo(triangles[i][0].dx, triangles[i][0].dy)
        ..lineTo(triangles[i][1].dx, triangles[i][1].dy)
        ..lineTo(triangles[i][2].dx, triangles[i][2].dy)
        ..close();
      final paint = Paint()..color = colors[i].withOpacity(0.35);
      canvas.drawPath(path, paint);
    }

    // Center star
    _drawStar(canvas, Offset(cx, cy), cw * 0.8, Colors.white.withOpacity(0.5));
  }

  void _drawGrid(Canvas canvas, Size size, double cw, double ch) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
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
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double cos(double r) => math_cos(r);
  double sin(double r) => math_sin(r);

  static double math_cos(double r) => _mathCos(r);
  static double math_sin(double r) => _mathSin(r);
  static double _mathCos(double r) {
    r = r % (2 * pi);
    double result = 1, term = 1;
    for (int i = 1; i <= 10; i++) { term *= -r * r / ((2*i-1) * (2*i)); result += term; }
    return result;
  }
  static double _mathSin(double r) {
    r = r % (2 * pi);
    double result = r, term = r;
    for (int i = 1; i <= 10; i++) { term *= -r * r / ((2*i) * (2*i+1)); result += term; }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
