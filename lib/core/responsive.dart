import 'package:flutter/material.dart';

/// Breakpoints za responsive layout
/// Telefon: < 600, Tablet: 600-1200, Desktop: > 1200
class Breakpoints {
  Breakpoints._();

  static const double phone = 600;
  static const double tablet = 1200;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide < phone;

  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= phone;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= tablet;

  /// Maksimalna širina sadržaja na tablet/desktop (centrirano)
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) return 1000;
    if (width >= phone) return 700;
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
    if (isPhone(context)) return 4;
    return 6;
  }
}
