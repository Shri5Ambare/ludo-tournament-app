// lib/widgets/token/token_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/game_models.dart';
import '../../core/constants/board_paths.dart';

class TokenWidget extends StatelessWidget {
  final Token token;
  final Player player;
  final bool isMovable;
  final VoidCallback? onTap;

  const TokenWidget({
    super.key,
    required this.token,
    required this.player,
    this.isMovable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = BoardPaths.playerColors[player.index];
    final isFinished = token.isFinished;

    Widget tokenBody = GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isMovable ? Colors.white : color.withValues(alpha: 0.8),
            width: isMovable ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isMovable ? 0.8 : 0.4),
              blurRadius: isMovable ? 12 : 4,
              spreadRadius: isMovable ? 2 : 0,
            ),
          ],
          gradient: isFinished
              ? null
              : RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: [
                    color.withValues(alpha: 0.95),
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                ),
        ),
        child: Center(
          child: isFinished
              ? const Text('✓', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
              : Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
        ),
      ),
    );

    // Pulsing glow when movable
    if (isMovable) {
      tokenBody = tokenBody
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.2, 1.2),
            duration: 600.ms,
            curve: Curves.easeInOut,
          );
    }

    return tokenBody;
  }
}
