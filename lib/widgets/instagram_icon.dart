import 'package:flutter/material.dart';

/// Autentična Instagram ikona sa prepoznatljivim radijalnim gradijentom i kamerom.
class InstagramIcon extends StatelessWidget {
  final double size;

  const InstagramIcon({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final outerBorderWidth = (size * 0.075).clamp(0.8, 1.2);
    final innerBorderWidth = (size * 0.065).clamp(0.7, 1.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const RadialGradient(
          center: Alignment(-0.8, 1.1),
          radius: 1.5,
          colors: [
            Color(0xFFFEDA77),
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
            Color(0xFF515BD4),
          ],
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 0.72,
              height: size * 0.72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.22),
                border: Border.all(color: Colors.white, width: outerBorderWidth),
              ),
              child: Center(
                child: Container(
                  width: size * 0.32,
                  height: size * 0.32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: innerBorderWidth),
                  ),
                ),
              ),
            ),
            Positioned(
              top: size * 0.18,
              right: size * 0.18,
              child: Container(
                width: (size * 0.12).clamp(1.2, 3.0),
                height: (size * 0.12).clamp(1.2, 3.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
