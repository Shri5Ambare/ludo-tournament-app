// lib/widgets/dice/dice_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class DiceWidget extends StatefulWidget {
  final int value;
  final bool canRoll;
  final VoidCallback onRoll;
  final Color playerColor;

  const DiceWidget({
    super.key,
    required this.value,
    required this.canRoll,
    required this.onRoll,
    required this.playerColor,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnim;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotationAnim = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRoll() {
    if (!widget.canRoll || _isAnimating) return;
    setState(() => _isAnimating = true);
    _controller.forward(from: 0).then((_) {
      setState(() => _isAnimating = false);
      widget.onRoll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleRoll,
      child: AnimatedBuilder(
        animation: _rotationAnim,
        builder: (context, child) {
          return Transform.rotate(
            angle: _isAnimating ? _rotationAnim.value : 0,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: widget.canRoll
                ? widget.playerColor.withOpacity(0.15)
                : AppColors.darkCard,
            border: Border.all(
              color: widget.canRoll ? widget.playerColor : AppColors.darkBorder,
              width: widget.canRoll ? 2.5 : 1.5,
            ),
            boxShadow: widget.canRoll
                ? [
                    BoxShadow(
                      color: widget.playerColor.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: widget.value == 0
                ? Icon(
                    Icons.casino_rounded,
                    color: widget.canRoll ? widget.playerColor : Colors.white38,
                    size: 36,
                  )
                : _DiceFace(value: widget.value, color: widget.playerColor),
          ),
        ),
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  final int value;
  final Color color;
  const _DiceFace({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final dots = _getDotPositions(value);
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: dots.map((pos) {
          return Positioned(
            left: pos.dx * 48 - 5,
            top: pos.dy * 48 - 5,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.elasticOut);
  }

  List<Offset> _getDotPositions(int value) {
    switch (value) {
      case 1:
        return [const Offset(0.5, 0.5)];
      case 2:
        return [const Offset(0.25, 0.25), const Offset(0.75, 0.75)];
      case 3:
        return [const Offset(0.25, 0.25), const Offset(0.5, 0.5), const Offset(0.75, 0.75)];
      case 4:
        return [
          const Offset(0.25, 0.25), const Offset(0.75, 0.25),
          const Offset(0.25, 0.75), const Offset(0.75, 0.75),
        ];
      case 5:
        return [
          const Offset(0.25, 0.25), const Offset(0.75, 0.25),
          const Offset(0.5, 0.5),
          const Offset(0.25, 0.75), const Offset(0.75, 0.75),
        ];
      case 6:
        return [
          const Offset(0.25, 0.2), const Offset(0.75, 0.2),
          const Offset(0.25, 0.5), const Offset(0.75, 0.5),
          const Offset(0.25, 0.8), const Offset(0.75, 0.8),
        ];
      default:
        return [];
    }
  }
}
