import 'package:flutter/material.dart';

/// Breakpoints za responsive layout
/// Phone: < 600, Tablet: 600-1200, Desktop: > 1200
class Breakpoints {
  Breakpoints._();

  static const double phone = 600;
  static const double tablet = 1200;

  /// Vraća skaliran font-size na osnovu device-a
  /// Tablet: +2-3px boost, Desktop: +4-5px boost
  static double scaleFontSize(double baseFontSize, BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) {
      // Desktop: veći boost
      return baseFontSize + (baseFontSize < 16 ? 4 : 5);
    } else if (width >= phone) {
      // Tablet: manji boost
      return baseFontSize + (baseFontSize < 16 ? 2 : 3);
    }
    // Mobile: bez promene
    return baseFontSize;
  }

  /// Prilagođena TextStyle sa responsive font-size
  static TextStyle responsiveTextStyle(
    TextStyle baseStyle,
    BuildContext context,
  ) {
    return baseStyle.copyWith(
      fontSize: scaleFontSize(baseStyle.fontSize ?? 14, context),
    );
  }

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phone;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= phone && width < tablet;
  }

  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= phone;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  /// Maksimalna širina sadržaja na tablet/desktop (centrirano)
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) return 1200;
    if (width >= phone) return 800;
    return double.infinity;
  }

  /// Broj kolona za product grid
  static int productGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) return 4;
    if (width >= phone) return 3;
    return 2;
  }

  /// Broj kolona za category chips (koliko stane u jedan red)
  static int categoryChipsPerRow(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) return 8;
    if (width >= phone) return 5;
    return 4;
  }

  /// Horizontalni padding za različite uređaje
  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }

  /// Vertikalni spacing između sekcija
  static double sectionSpacing(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }
}
