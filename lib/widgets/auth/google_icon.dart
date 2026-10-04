import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pixel-perfect Google 'G' logo drawn via Canvas primitives.
///
/// Uses the official Google brand colors:
/// - Blue:   #4285F4
/// - Red:    #EA4335
/// - Yellow: #FBBC05
/// - Green:  #34A853
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;
    final strokeWidth = radius * 0.42;
    final arcRadius = radius - strokeWidth / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: arcRadius);

    Paint makePaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 1. Red (top): from -135° to -45° (approx 90 deg)
    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.5, false,
        makePaint(const Color(0xFFEA4335)));

    // 2. Yellow (left): from 135° to 225° (which is -135°)
    canvas.drawArc(rect, math.pi * 0.75, math.pi * 0.5, false,
        makePaint(const Color(0xFFFBBC05)));

    // 3. Green (bottom): from 45° to 135°
    canvas.drawArc(rect, math.pi * 0.25, math.pi * 0.5, false,
        makePaint(const Color(0xFF34A853)));

    // 4. Blue (bottom-right to center bar)
    canvas.drawArc(rect, 0, math.pi * 0.25, false,
        makePaint(const Color(0xFF4285F4)));

    // Blue horizontal bar in the middle
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barHeight = strokeWidth;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        cx - strokeWidth * 0.1,
        cy - barHeight / 2,
        radius * 1.0 - (cx - strokeWidth * 0.1),
        barHeight,
      ),
      Radius.circular(strokeWidth * 0.15),
    );
    canvas.drawRRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
