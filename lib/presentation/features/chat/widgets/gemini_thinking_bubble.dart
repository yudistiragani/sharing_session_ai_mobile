// lib/presentation/features/chat/widgets/gemini_thinking_bubble.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Compact GeminiThinkingBubble with a fast rainbow solid stripe orbiting avatar.
/// Defaults tuned: avatarSize=36, ringRadius=24, ringThickness=5, rotationSeconds=0.85
class GeminiThinkingBubble extends StatefulWidget {
  final double avatarSize;
  final double ringRadius; // distance from center to ring
  final double ringThickness;
  final double rotationSeconds;

  const GeminiThinkingBubble({
    super.key,
    this.avatarSize = 36,
    this.ringRadius = 24,
    this.ringThickness = 5,
    this.rotationSeconds = 0.85,
  });

  @override
  State<GeminiThinkingBubble> createState() => _GeminiThinkingBubbleState();
}

class _GeminiThinkingBubbleState extends State<GeminiThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.rotationSeconds * 1000).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSize = (widget.ringRadius + widget.ringThickness) * 2;
    // Keep compact height slightly larger than avatar
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: widget.avatarSize + 8,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            Stack(
              alignment: Alignment.center,
              children: [
                // rotating rainbow arc
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _ctrl.value * 2 * math.pi,
                      child: child,
                    );
                  },
                  child: CustomPaint(
                    size: Size(totalSize, totalSize),
                    painter: _RainbowArcPainter(
                      radius: widget.ringRadius,
                      thickness: widget.ringThickness,
                    ),
                  ),
                ),

                // avatar circle (compact)
                Container(
                  width: widget.avatarSize,
                  height: widget.avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.grey[100],
                    border: Border.all(color: Colors.white, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.smart_toy,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      size: widget.avatarSize * 0.46,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter that draws a solid rainbow arc (not blurred)
class _RainbowArcPainter extends CustomPainter {
  final double radius;
  final double thickness;

  _RainbowArcPainter({required this.radius, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: const [
        Color(0xFFE53935),
        Color(0xFFFDD835),
        Color(0xFF43A047),
        Color(0xFF1E88E5),
        Color(0xFF5E35B1),
        Color(0xFFE53935),
      ],
      stops: const [0.0, 0.18, 0.45, 0.68, 0.86, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness
      ..shader = gradient.createShader(rect);

    final start = -math.pi / 5;
    final sweep = math.pi * 1.4;
    canvas.drawArc(rect, start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RainbowArcPainter old) {
    return old.radius != radius || old.thickness != thickness;
  }
}
