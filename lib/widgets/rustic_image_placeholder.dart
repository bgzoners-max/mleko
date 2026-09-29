import 'package:flutter/material.dart';

import '../constants/amazon_theme.dart';

/// Topla, zanatska ilustracija-placeholder za proizvode bez fotografije.
///
/// Zamenjuje sterilnu sivu ikonicu (Icons.inventory_2) motivom "sanduk sa
/// plodovima" u brend paleti — lanena podloga, zlatni sanduk, terakota i
/// medeno zlato, listić u prirodnoj zelenoj. Ručno "nacrtan" osećaj dolazi
/// od mekih, zaobljenih poteza (strokeCap.round) i blage asimetrije.
class RusticImagePlaceholder extends StatelessWidget {
  const RusticImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AmazonColors.darkCard : const Color(0xFFF0EDE5);

    return Container(
      color: bg,
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size(88, 88),
        painter: _RusticCratePainter(isDark: isDark),
      ),
    );
  }
}

class _RusticCratePainter extends CustomPainter {
  final bool isDark;

  const _RusticCratePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Brend paleta; u tamnom režimu boje su prigušene da ne "svetle".
    final wood = isDark ? AmazonColors.gold.withValues(alpha: 0.55) : AmazonColors.gold;
    final terracotta = isDark
        ? AmazonColors.badgeRed.withValues(alpha: 0.55)
        : AmazonColors.badgeRed;
    final honey = isDark
        ? AmazonColors.amberLight.withValues(alpha: 0.55)
        : AmazonColors.amberLight;
    final leaf = isDark
        ? AmazonColors.green.withValues(alpha: 0.55)
        : AmazonColors.green;

    final s = size.shortestSide;

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = wood.withValues(alpha: isDark ? 0.16 : 0.22);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = wood;

    // ── Plodovi koji virе iznad sanduka (blaga asimetrija) ──
    final r = s * 0.11;
    final fruitPaint = Paint()..style = PaintingStyle.fill;
    fruitPaint.color = terracotta;
    canvas.drawCircle(Offset(s * 0.36, s * 0.40), r, fruitPaint);
    fruitPaint.color = honey;
    canvas.drawCircle(Offset(s * 0.52, s * 0.35), r * 1.05, fruitPaint);
    fruitPaint.color = terracotta.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(s * 0.66, s * 0.42), r * 0.9, fruitPaint);

    // ── Listić na srednjem plodu ──
    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = leaf;
    final leafPath = Path()
      ..moveTo(s * 0.52, s * 0.24)
      ..quadraticBezierTo(s * 0.60, s * 0.16, s * 0.66, s * 0.22)
      ..quadraticBezierTo(s * 0.58, s * 0.28, s * 0.52, s * 0.24)
      ..close();
    canvas.drawPath(leafPath, leafPaint);
    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.02
      ..strokeCap = StrokeCap.round
      ..color = leaf;
    canvas.drawLine(
        Offset(s * 0.52, s * 0.25), Offset(s * 0.53, s * 0.31), stemPaint);

    // ── Drveni sanduk: blagi trapez (širi na vrhu — ručni rad) ──
    final crate = Path()
      ..moveTo(s * 0.22, s * 0.55)
      ..lineTo(s * 0.78, s * 0.55)
      ..lineTo(s * 0.72, s * 0.82)
      ..lineTo(s * 0.28, s * 0.82)
      ..close();
    canvas.drawPath(crate, fill);
    canvas.drawPath(crate, stroke);

    // ── Letvice sanduka ──
    final slat = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..strokeCap = StrokeCap.round
      ..color = wood.withValues(alpha: 0.7);
    canvas.drawLine(Offset(s * 0.255, s * 0.64), Offset(s * 0.745, s * 0.64), slat);
    canvas.drawLine(Offset(s * 0.267, s * 0.73), Offset(s * 0.733, s * 0.73), slat);
  }

  @override
  bool shouldRepaint(covariant _RusticCratePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
