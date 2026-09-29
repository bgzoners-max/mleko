import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/amazon_theme.dart';

/// Suptilna "ručno prošivena" linija — organska zamena za strogi pravi
/// razdelnik. Blago talasa i isprekidana je, kao konac na lanu, čime se
/// razbija utisak fabrički poravnatih pravougaonika.
class OrganicDivider extends StatelessWidget {
  final double height;
  final double dashWidth;
  final double gapWidth;
  final Color? color;

  const OrganicDivider({
    super.key,
    this.height = 8,
    this.dashWidth = 7,
    this.gapWidth = 5,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolved = color ??
        (isDark
            ? AmazonColors.darkTextSecondary.withValues(alpha: 0.45)
            : AmazonColors.textSecondary.withValues(alpha: 0.38));

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _StitchedLinePainter(
          color: resolved,
          dash: dashWidth,
          gap: gapWidth,
        ),
      ),
    );
  }
}

class _StitchedLinePainter extends CustomPainter {
  final Color color;
  final double dash;
  final double gap;

  const _StitchedLinePainter({
    required this.color,
    required this.dash,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Blagi, asimetričan talas (ne prava linija).
    final path = Path()
      ..moveTo(0, h * 0.55)
      ..cubicTo(w * 0.22, h * 0.10, w * 0.48, h * 0.95, w, h * 0.45);

    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StitchedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap;
}
