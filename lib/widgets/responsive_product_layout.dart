import 'package:flutter/material.dart';
import '../core/responsive.dart';

/// Responsive layout za product detail - slike levo, info desno na tablet/desktop
class ResponsiveProductLayout extends StatelessWidget {
  final Widget imageWidget;
  final Widget infoWidget;
  final double imageHeight;
  final double? imageWidth;

  const ResponsiveProductLayout({
    required this.imageWidget,
    required this.infoWidget,
    this.imageHeight = 220,
    this.imageWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = Breakpoints.isTabletOrLarger(context);

    if (isTabletOrLarger) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leva kolona - slike (50% ili fiksna širina)
          SizedBox(
            width: imageWidth ?? MediaQuery.sizeOf(context).width * 0.45,
            child: SizedBox(
              height: 400,
              child: imageWidget,
            ),
          ),
          const SizedBox(width: 24),
          // Desna kolona - info
          Expanded(
            child: SingleChildScrollView(
              child: infoWidget,
            ),
          ),
        ],
      );
    }

    // Mobile - vertikalni layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: imageHeight, child: imageWidget),
        infoWidget,
      ],
    );
  }
}
