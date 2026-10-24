import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/amazon_theme.dart';

/// Motiv rustic ilustracije — koristi se u praznim stanjima umesto
/// generičkih Material ikonica.
enum RusticMotif {
  /// Prazna korpa / lista želja.
  basket,

  /// Nema ponude u regionu (pejzaž sa ambarom).
  field,

  /// Pretraga bez rezultata.
  search,

  /// Puna korpa (onboarding: kupovina direktno od proizvođača).
  fullBasket,

  /// Rustična dostava (onboarding: preuzimanje, dostava ili dogovor).
  delivery,
}

/// Topla, "ručno crtana" ilustracija u brend paleti (lan, zlato, terakota,
/// livada). Zamenjuje sterilne sive ikonice i drži isti vizuelni jezik kao
/// placeholder na karticama proizvoda.
class RusticIllustration extends StatelessWidget {
  final RusticMotif motif;
  final double size;

  const RusticIllustration({
    super.key,
    required this.motif,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: switch (motif) {
          RusticMotif.basket => _BasketPainter(isDark: isDark),
          RusticMotif.field => _FieldPainter(isDark: isDark),
          RusticMotif.search => _SearchPainter(isDark: isDark),
          RusticMotif.fullBasket => _FullBasketPainter(isDark: isDark),
          RusticMotif.delivery => _DeliveryPainter(isDark: isDark),
        },
      ),
    );
  }
}

/// Prigušuje boje u tamnom režimu da ne "svetle" previše.
Color _soft(Color color, bool isDark) =>
    isDark ? color.withValues(alpha: 0.6) : color;

// ─────────────────────────────────────────────────────────────────────────────
// Prazna korpa / lista želja
// ─────────────────────────────────────────────────────────────────────────────
class _BasketPainter extends CustomPainter {
  final bool isDark;
  const _BasketPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final wood = _soft(AmazonColors.gold, isDark);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.032
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = wood;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = wood.withValues(alpha: isDark ? 0.14 : 0.18);

    canvas
      ..save()
      // Blagi nagib — ručno pletena korpa nikad nije savršeno ravna.
      ..translate(s * 0.5, s * 0.55)
      ..rotate(0.05)
      ..translate(-s * 0.5, -s * 0.55)
      // Ručka
      ..drawArc(
        Rect.fromCircle(center: Offset(s * 0.5, s * 0.44), radius: s * 0.20),
        math.pi,
        math.pi,
        false,
        stroke,
      );

    // Telo korpe (blagi trapez)
    final body = Path()
      ..moveTo(s * 0.22, s * 0.54)
      ..lineTo(s * 0.78, s * 0.54)
      ..lineTo(s * 0.69, s * 0.85)
      ..lineTo(s * 0.31, s * 0.85)
      ..close();
    canvas
      ..drawPath(body, fill)
      ..drawPath(body, stroke);

    // Pletenje
    final weave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.02
      ..strokeCap = StrokeCap.round
      ..color = wood.withValues(alpha: 0.55);
    canvas
      ..drawLine(Offset(s * 0.24, s * 0.64), Offset(s * 0.76, s * 0.64), weave)
      ..drawLine(Offset(s * 0.27, s * 0.75), Offset(s * 0.73, s * 0.75), weave)
      ..drawLine(Offset(s * 0.5, s * 0.54), Offset(s * 0.5, s * 0.85), weave)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _BasketPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pejzaž (nema ponude u regionu)
// ─────────────────────────────────────────────────────────────────────────────
class _FieldPainter extends CustomPainter {
  final bool isDark;
  const _FieldPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final green = _soft(AmazonColors.green, isDark);
    final amber = _soft(AmazonColors.amberLight, isDark);
    final terracotta = _soft(AmazonColors.dealRed, isDark);
    final wood = _soft(AmazonColors.gold, isDark);

    // Sunce
    canvas.drawCircle(
      Offset(s * 0.74, s * 0.26),
      s * 0.10,
      Paint()
        ..style = PaintingStyle.fill
        ..color = amber.withValues(alpha: isDark ? 0.55 : 0.85),
    );

    // Zadnje brdo
    final backHill = Path()
      ..moveTo(s * 0.06, s * 0.72)
      ..quadraticBezierTo(s * 0.5, s * 0.38, s * 0.94, s * 0.72)
      ..lineTo(s * 0.94, s * 0.80)
      ..lineTo(s * 0.06, s * 0.80)
      ..close();
    canvas.drawPath(
      backHill,
      Paint()
        ..style = PaintingStyle.fill
        ..color = green.withValues(alpha: isDark ? 0.18 : 0.22),
    );

    // Prednje brdo
    final frontHill = Path()
      ..moveTo(-s * 0.04, s * 0.84)
      ..quadraticBezierTo(s * 0.36, s * 0.58, s * 1.04, s * 0.84)
      ..lineTo(s * 1.04, s * 0.92)
      ..lineTo(-s * 0.04, s * 0.92)
      ..close();
    canvas
      ..drawPath(
        frontHill,
        Paint()
          ..style = PaintingStyle.fill
          ..color = green.withValues(alpha: isDark ? 0.28 : 0.32),
      )
      // Ambar: telo + krov
      ..drawRect(
        Rect.fromLTWH(s * 0.30, s * 0.56, s * 0.16, s * 0.14),
        Paint()
          ..style = PaintingStyle.fill
          ..color = terracotta.withValues(alpha: isDark ? 0.6 : 0.85),
      );
    final roof = Path()
      ..moveTo(s * 0.27, s * 0.56)
      ..lineTo(s * 0.38, s * 0.45)
      ..lineTo(s * 0.49, s * 0.56)
      ..close();
    canvas
      ..drawPath(
        roof,
        Paint()
          ..style = PaintingStyle.fill
          ..color = wood.withValues(alpha: isDark ? 0.6 : 0.9),
      )
      // Drvo (krošnja + deblo)
      ..drawCircle(
        Offset(s * 0.66, s * 0.62),
        s * 0.075,
        Paint()
          ..style = PaintingStyle.fill
          ..color = green.withValues(alpha: isDark ? 0.35 : 0.45),
      )
      ..drawLine(
        Offset(s * 0.66, s * 0.68),
        Offset(s * 0.66, s * 0.78),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.022
          ..strokeCap = StrokeCap.round
          ..color = wood.withValues(alpha: 0.8),
      );
  }

  @override
  bool shouldRepaint(covariant _FieldPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pretraga bez rezultata
// ─────────────────────────────────────────────────────────────────────────────
class _SearchPainter extends CustomPainter {
  final bool isDark;
  const _SearchPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final wood = _soft(AmazonColors.gold, isDark);
    final green = _soft(AmazonColors.green, isDark);
    final amber = _soft(AmazonColors.amberLight, isDark);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round
      ..color = wood;
    final fillSoft = Paint()
      ..style = PaintingStyle.fill
      ..color = wood.withValues(alpha: isDark ? 0.10 : 0.13);

    final center = Offset(s * 0.44, s * 0.44);
    final radius = s * 0.24;

    canvas
      ..drawCircle(center, radius, fillSoft)
      ..drawCircle(center, radius, ring)
      // Drška lupe
      ..drawLine(
        Offset(center.dx + radius * 0.72, center.dy + radius * 0.72),
        Offset(s * 0.82, s * 0.82),
        ring,
      )
      // Klica unutra — simbol svežeg, još nepronađenog
      ..drawLine(
        Offset(s * 0.44, s * 0.56),
        Offset(s * 0.44, s * 0.36),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.028
          ..strokeCap = StrokeCap.round
          ..color = green,
      );

    final leftLeaf = Path()
      ..moveTo(s * 0.44, s * 0.47)
      ..quadraticBezierTo(s * 0.32, s * 0.40, s * 0.34, s * 0.32)
      ..quadraticBezierTo(s * 0.42, s * 0.33, s * 0.44, s * 0.47)
      ..close();
    final rightLeaf = Path()
      ..moveTo(s * 0.44, s * 0.43)
      ..quadraticBezierTo(s * 0.56, s * 0.36, s * 0.54, s * 0.28)
      ..quadraticBezierTo(s * 0.46, s * 0.29, s * 0.44, s * 0.43)
      ..close();
    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = green.withValues(alpha: isDark ? 0.55 : 0.75);
    canvas
      ..drawPath(leftLeaf, leafPaint)
      ..drawPath(rightLeaf, leafPaint)
      // Zrne
      ..drawCircle(
        Offset(s * 0.44, s * 0.33),
        s * 0.028,
        Paint()
          ..style = PaintingStyle.fill
          ..color = amber,
      );
  }

  @override
  bool shouldRepaint(covariant _SearchPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Puna korpa (onboarding)
// ─────────────────────────────────────────────────────────────────────────────
class _FullBasketPainter extends CustomPainter {
  final bool isDark;
  const _FullBasketPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final wood = _soft(AmazonColors.gold, isDark);
    final green = _soft(AmazonColors.green, isDark);
    final amber = _soft(AmazonColors.amberLight, isDark);
    final terracotta = _soft(AmazonColors.badgeRed, isDark);

    // Plodovi koji vire iz korpe
    canvas
      ..drawCircle(
        Offset(s * 0.34, s * 0.44),
        s * 0.085,
        Paint()
          ..style = PaintingStyle.fill
          ..color = green.withValues(alpha: 0.85),
      )
      ..drawCircle(
        Offset(s * 0.50, s * 0.38),
        s * 0.105,
        Paint()
          ..style = PaintingStyle.fill
          ..color = terracotta.withValues(alpha: 0.9),
      )
      ..drawCircle(
        Offset(s * 0.67, s * 0.45),
        s * 0.08,
        Paint()
          ..style = PaintingStyle.fill
          ..color = amber,
      );

    // Listić na srednjem plodu
    final leaf = Path()
      ..moveTo(s * 0.50, s * 0.26)
      ..quadraticBezierTo(s * 0.58, s * 0.17, s * 0.65, s * 0.24)
      ..quadraticBezierTo(s * 0.57, s * 0.30, s * 0.50, s * 0.26)
      ..close();
    canvas.drawPath(
      leaf,
      Paint()
        ..style = PaintingStyle.fill
        ..color = green,
    );

    // Korpa (trapez)
    final body = Path()
      ..moveTo(s * 0.20, s * 0.52)
      ..lineTo(s * 0.80, s * 0.52)
      ..lineTo(s * 0.70, s * 0.84)
      ..lineTo(s * 0.30, s * 0.84)
      ..close();
    canvas
      ..drawPath(
        body,
        Paint()
          ..style = PaintingStyle.fill
          ..color = wood.withValues(alpha: isDark ? 0.14 : 0.18),
      )
      ..drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.032
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = wood,
      );

    // Pletenje
    final weave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.02
      ..strokeCap = StrokeCap.round
      ..color = wood.withValues(alpha: 0.55);
    canvas
      ..drawLine(Offset(s * 0.23, s * 0.62), Offset(s * 0.77, s * 0.62), weave)
      ..drawLine(Offset(s * 0.26, s * 0.73), Offset(s * 0.74, s * 0.73), weave)
      ..drawLine(Offset(s * 0.40, s * 0.52), Offset(s * 0.36, s * 0.84), weave)
      ..drawLine(Offset(s * 0.60, s * 0.52), Offset(s * 0.64, s * 0.84), weave);
  }

  @override
  bool shouldRepaint(covariant _FullBasketPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Rustično dostavno vozilo (onboarding)
// ─────────────────────────────────────────────────────────────────────────────
class _DeliveryPainter extends CustomPainter {
  final bool isDark;
  const _DeliveryPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final wood = _soft(AmazonColors.gold, isDark);
    final green = _soft(AmazonColors.green, isDark);
    final terracotta = _soft(AmazonColors.dealRed, isDark);
    final slate = isDark ? AmazonColors.darkTextSecondary : AmazonColors.slate;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.032
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = wood;
    final lightFill = Paint()
      ..style = PaintingStyle.fill
      ..color = wood.withValues(alpha: isDark ? 0.12 : 0.16);

    // Tovarni deo (karoserija)
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.14, s * 0.40, s * 0.50, s * 0.26),
      Radius.circular(s * 0.04),
    );
    canvas
      ..drawRRect(body, lightFill)
      ..drawRRect(body, stroke);

    // Kabina
    final cabin = Path()
      ..moveTo(s * 0.64, s * 0.48)
      ..lineTo(s * 0.78, s * 0.48)
      ..lineTo(s * 0.88, s * 0.62)
      ..lineTo(s * 0.64, s * 0.62)
      ..close();
    canvas
      ..drawPath(cabin, lightFill)
      ..drawPath(cabin, stroke);

    // Prozor kabine
    final window = Path()
      ..moveTo(s * 0.68, s * 0.51)
      ..lineTo(s * 0.77, s * 0.51)
      ..lineTo(s * 0.83, s * 0.60)
      ..lineTo(s * 0.68, s * 0.60)
      ..close();
    canvas
      ..drawPath(
        window,
        Paint()
          ..style = PaintingStyle.fill
          ..color = green.withValues(alpha: 0.55),
      )
      // Ukrasna traka — "domaći potpis" na vozilu
      ..drawLine(
        Offset(s * 0.20, s * 0.545),
        Offset(s * 0.58, s * 0.545),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.03
          ..strokeCap = StrokeCap.round
          ..color = terracotta.withValues(alpha: 0.8),
      );

    // Točkovi
    final tyre = Paint()
      ..style = PaintingStyle.fill
      ..color = slate;
    final hub = Paint()
      ..style = PaintingStyle.fill
      ..color = wood;
    canvas
      ..drawCircle(Offset(s * 0.30, s * 0.68), s * 0.075, tyre)
      ..drawCircle(Offset(s * 0.30, s * 0.68), s * 0.03, hub)
      ..drawCircle(Offset(s * 0.74, s * 0.68), s * 0.075, tyre)
      ..drawCircle(Offset(s * 0.74, s * 0.68), s * 0.03, hub)
      // Tlo
      ..drawLine(
        Offset(s * 0.12, s * 0.78),
        Offset(s * 0.88, s * 0.78),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.022
          ..strokeCap = StrokeCap.round
          ..color = wood.withValues(alpha: 0.45),
      );
  }

  @override
  bool shouldRepaint(covariant _DeliveryPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}



