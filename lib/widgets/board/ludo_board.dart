// lib/widgets/board/ludo_board.dart
import 'package:flutter/material.dart';
import '../../core/constants/board_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_models.dart';
import '../token/token_widget.dart';

class LudoBoard extends StatelessWidget {
  final GameState gameState;
  final Function(int tokenId) onTokenTap;

  const LudoBoard({
    super.key,
    required this.gameState,
    required this.onTokenTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final cellSize = size / 15;
          return Stack(
            children: [
              // Board background
              _buildBoardBackground(size, cellSize),
              // Tokens on top
              ..._buildAllTokens(cellSize),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBoardBackground(double size, double cellSize) {
    return CustomPaint(
      size: Size(size, size),
      painter: BoardPainter(cellSize: cellSize),
    );
  }

  List<Widget> _buildAllTokens(double cellSize) {
    final widgets = <Widget>[];

    for (final player in gameState.players) {
      for (final token in player.tokens) {
        final cell = token.boardCell;
        final row = cell[0];
        final col = cell[1];
        final isMovable = gameState.movableTokenIds.contains(token.id) &&
            gameState.currentPlayerIndex == player.index;

        widgets.add(
          Positioned(
            left: col * cellSize + cellSize * 0.1,
            top: row * cellSize + cellSize * 0.1,
            width: cellSize * 0.8,
            height: cellSize * 0.8,
            child: TokenWidget(
              token: token,
              player: player,
              isMovable: isMovable,
              onTap: isMovable ? () => onTokenTap(token.id) : null,
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

// ─────────────────────────────────────────────
// Board Painter
// ─────────────────────────────────────────────

class BoardPainter extends CustomPainter {
  final double cellSize;

  BoardPainter({required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGrid(canvas, size);
    _drawHomeYards(canvas);
    _drawSafeZones(canvas);
    _drawArrows(canvas);
    _drawHomeColumns(canvas);
    _drawCenter(canvas, size);
    _drawBorder(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A1035);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.darkBorder.withValues(alpha: 0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 15; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), paint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), paint);
    }
  }

  void _drawHomeYards(Canvas canvas) {
    final colors = [
      AppColors.redPlayer,
      AppColors.greenPlayer,
      AppColors.yellowPlayer,
      AppColors.bluePlayer,
    ];

    // Home yard quadrant rects (6x6 areas)
    final quadrants = [
      const Rect.fromLTWH(0, 0, 6, 6),       // Red - top left
      const Rect.fromLTWH(9, 0, 6, 6),       // Green - top right
      const Rect.fromLTWH(9, 9, 6, 6),       // Yellow - bottom right
      const Rect.fromLTWH(0, 9, 6, 6),       // Blue - bottom left
    ];

    for (int i = 0; i < 4; i++) {
      final rect = quadrants[i];
      final scaledRect = Rect.fromLTWH(
        rect.left * cellSize,
        rect.top * cellSize,
        rect.width * cellSize,
        rect.height * cellSize,
      );

      // Outer fill
      final bgPaint = Paint()..color = colors[i].withValues(alpha: 0.15);
      canvas.drawRRect(
          RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)),
          bgPaint);

      // Border
      final borderPaint = Paint()
        ..color = colors[i].withValues(alpha: 0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
          RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)),
          borderPaint);

      // Inner yard circle
      final innerRect = Rect.fromLTWH(
        (rect.left + 0.8) * cellSize,
        (rect.top + 0.8) * cellSize,
        (rect.width - 1.6) * cellSize,
        (rect.height - 1.6) * cellSize,
      );
      final innerPaint = Paint()..color = colors[i].withValues(alpha: 0.25);
      canvas.drawOval(innerRect, innerPaint);
    }
  }

  void _drawSafeZones(Canvas canvas) {
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);

    for (final safePos in BoardPaths.safePositions) {
      final cell = BoardPaths.mainPath[safePos];
      final cx = (cell[1] + 0.5) * cellSize;
      final cy = (cell[0] + 0.5) * cellSize;
      _drawStar(canvas, cx, cy, cellSize * 0.35, starPaint);
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * 36 - 90) * 3.14159 / 180;
      final radius = i.isEven ? r : r * 0.4;
      final x = cx + radius * _cos(angle);
      final y = cy + radius * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double angle) => (angle * 180 / 3.14159).toDouble() * 0 + _cosRad(angle);
  double _cosRad(double rad) {
    // Taylor series approximation
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 8; i++) {
      term *= -rad * rad / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _sin(double angle) => _sinRad(angle);
  double _sinRad(double rad) {
    double result = rad;
    double term = rad;
    for (int i = 1; i <= 8; i++) {
      term *= -rad * rad / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  void _drawArrows(Canvas canvas) {
    // Draw colored path cells for each player
    final colors = [
      AppColors.redPlayer,
      AppColors.greenPlayer,
      AppColors.yellowPlayer,
      AppColors.bluePlayer,
    ];

    // Player approach cells (last 5 on main path before home entry)
    // These are colored in the player's color
    final approachCells = [
      [for (int i = 0; i < 5; i++) (i)],        // Red: 0-4
      [for (int i = 13; i < 18; i++) i],         // Green: 13-17
      [for (int i = 26; i < 31; i++) i],         // Yellow: 26-30
      [for (int i = 39; i < 44; i++) i],         // Blue: 39-43
    ];

    for (int p = 0; p < 4; p++) {
      final paint = Paint()..color = colors[p].withValues(alpha: 0.35);
      for (final idx in approachCells[p]) {
        if (idx >= BoardPaths.mainPath.length) continue;
        final cell = BoardPaths.mainPath[idx];
        final rect = Rect.fromLTWH(
            cell[1] * cellSize, cell[0] * cellSize, cellSize, cellSize);
        canvas.drawRect(rect, paint);
      }
    }
  }

  void _drawHomeColumns(Canvas canvas) {
    final colors = [
      AppColors.redPlayer,
      AppColors.greenPlayer,
      AppColors.yellowPlayer,
      AppColors.bluePlayer,
    ];

    for (int p = 0; p < 4; p++) {
      final paint = Paint()..color = colors[p].withValues(alpha: 0.5);
      final cells = BoardPaths.homeColumns[p]!;
      for (final cell in cells) {
        final rect = Rect.fromLTWH(
            cell[1] * cellSize + 1,
            cell[0] * cellSize + 1,
            cellSize - 2,
            cellSize - 2);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(cellSize * 0.2)),
            paint);
      }
    }
  }

  void _drawCenter(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cellSize * 1.8;

    // Rainbow center
    final gradient = SweepGradient(
      colors: [
        AppColors.redPlayer,
        AppColors.greenPlayer,
        AppColors.yellowPlayer,
        AppColors.bluePlayer,
        AppColors.redPlayer,
      ],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2));
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Inner white circle
    final innerPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(cx, cy), r * 0.5, innerPaint);

    // Trophy emoji drawn via TextPainter
    final tp = TextPainter(
      text: const TextSpan(
          text: '🏆', style: TextStyle(fontSize: 18)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawBorder(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Radius.circular(cellSize * 0.5)),
        paint);
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) =>
      oldDelegate.cellSize != cellSize;
}
