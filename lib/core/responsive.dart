import 'package:flutter/material.dart';

const double kDesktopBreakpoint = 1200;

/// Breakpoints za responsive layout
/// Phone: < 600, Tablet: 600-1200, Desktop: >= 1200
class Breakpoints {
  Breakpoints._();

  static const double compactPhone = 360;
  static const double phone = 600;
  static const double smallTablet = 768;
  static const double largeTablet = 1024;
  static const double tablet = kDesktopBreakpoint;
  static const double desktop = kDesktopBreakpoint;
  static const double wideDesktop = 1440;

  /// Maksimalna širina za modalne prozore i sheet-ove na tablet/desktop ekranima
  static const double modalMaxWidth = 640;
  static const double compactModalMaxWidth = 480;

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

  static bool isCompactPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactPhone;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phone;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= phone && width < tablet;
  }

  static bool isSmallTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= phone && width < largeTablet;
  }

  static bool isLargeTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= largeTablet && width < tablet;
  }

  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= phone;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  static bool isWideDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideDesktop;

  static bool useDesktopSplitView(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1280;

  /// Dvopanelni raspored za data-heavy ekrane.
  /// Desktop ga uvek koristi, a veliki tableti samo u landscape orijentaciji.
  static bool useTwoPaneLayout(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1280) return true;
    return width >= largeTablet && isLandscape(context);
  }

  /// Maksimalna širina sadržaja na tablet/desktop (centrirano)
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) return 1200;
    if (width >= largeTablet) return 1040;
    if (width >= smallTablet) return 920;
    if (width >= phone) return 800;
    return double.infinity;
  }

  /// Širina za data-heavy desktop ekrane sa sidebar-om ili većom listom.
  static double dataContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wideDesktop) return 1360;
    if (width >= tablet) return 1280;
    if (width >= largeTablet) return 1040;
    if (width >= smallTablet) return 920;
    if (width >= phone) return 800;
    return double.infinity;
  }

  /// Čitljiva širina za forme i detail ekrane.
  /// Telefon ostaje fluidan, tablet dobija umeren okvir, a desktop 800px.
  static double formContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) return 800;
    if (width >= largeTablet) return 720;
    if (width >= smallTablet) return 680;
    if (width >= phone) return 640;
    return double.infinity;
  }

  /// Uža širina za auth tokove koji treba da ostanu fokusirani i na tabletu.
  static double authContentWidth(
    BuildContext context, {
    required double tabletWidth,
    double? desktopWidth,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) return desktopWidth ?? tabletWidth;
    if (width >= phone) return tabletWidth;
    return double.infinity;
  }

  /// Broj kolona za product grid (5 kolona na wide desktop 1440px+, 4 na standardnom desktopu)
  static int productGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wideDesktop) return 5;
    if (width >= tablet) return 4;
    if (width >= largeTablet) return 3;
    if (width >= phone) return 3;
    return 2;
  }

  /// Broj kolona za category chips (koliko stane u jedan red)
  static int categoryChipsPerRow(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) return 8;
    if (width >= largeTablet) return 6;
    if (width >= smallTablet) return 5;
    if (width >= phone) return 5;
    return 4;
  }

  /// Horizontalni padding za različite uređaje
  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isLargeTablet(context)) return 28;
    if (isSmallTablet(context)) return 24;
    if (isTablet(context)) return 24;
    return 16;
  }

  /// Vertikalni spacing između sekcija
  static double sectionSpacing(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isLargeTablet(context)) return 26;
    if (isSmallTablet(context)) return 20;
    if (isTablet(context)) return 24;
    return 16;
  }

  static double panelGap(BuildContext context) {
    return adaptiveDouble(
      context,
      phone: 16,
      smallTabletValue: 18,
      largeTabletValue: 20,
      desktop: 24,
    );
  }

  static double desktopSidebarWidth(BuildContext context) {
    if (isWideDesktop(context)) return 360;
    if (isDesktop(context)) return 320;
    if (isLargeTablet(context)) return 280;
    return 260;
  }

  /// Adaptivna numerička vrednost po breakpoint-u.
  static double adaptiveDouble(
    BuildContext context, {
    required double phone,
    double? smallTabletValue,
    double? largeTabletValue,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? largeTabletValue ?? smallTabletValue ?? phone;
    }
    if (isLargeTablet(context)) {
      return largeTabletValue ?? smallTabletValue ?? phone;
    }
    if (isSmallTablet(context)) {
      return smallTabletValue ?? phone;
    }
    return phone;
  }

  static double cardPadding(BuildContext context) {
    return adaptiveDouble(
      context,
      phone: 16,
      smallTabletValue: 18,
      largeTabletValue: 20,
      desktop: 20,
    );
  }

  static TextStyle? sectionTitleStyle(
    BuildContext context,
    TextStyle? baseStyle,
  ) {
    if (baseStyle == null) return null;
    final baseFontSize = baseStyle.fontSize ?? 16;
    return baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: adaptiveDouble(
        context,
        phone: baseFontSize,
        smallTabletValue: baseFontSize + 1,
        largeTabletValue: baseFontSize + 2,
        desktop: baseFontSize + 2,
      ),
    );
  }

  static TextStyle? heroTitleStyle(
    BuildContext context,
    TextStyle? baseStyle,
  ) {
    if (baseStyle == null) return null;
    final baseFontSize = baseStyle.fontSize ?? 24;
    return baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: adaptiveDouble(
        context,
        phone: baseFontSize,
        smallTabletValue: baseFontSize + 2,
        largeTabletValue: baseFontSize + 4,
        desktop: baseFontSize + 4,
      ),
    );
  }

  static TextStyle? supportingTextStyle(
    BuildContext context,
    TextStyle? baseStyle, {
    double phone = 13,
    double? smallTabletValue,
    double? largeTabletValue,
    double? desktop,
    double height = 1.4,
    Color? color,
  }) {
    if (baseStyle == null) return null;
    return baseStyle.copyWith(
      color: color ?? baseStyle.color,
      height: height,
      fontSize: adaptiveDouble(
        context,
        phone: phone,
        smallTabletValue: smallTabletValue,
        largeTabletValue: largeTabletValue,
        desktop: desktop,
      ),
    );
  }
}
