import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_system.dart';
import 'responsive.dart';

const double _minTouchTarget = 48.0;
/// Minimalni dodirni cilj po WCAG 2.1 AA smernicama iznosi 44×44 dp.
const double _minTouchTargetCompact = 44.0;

/// Izračunava minimalnu veličinu dodirnog cilja poštujući WCAG AA (44×44 dp)
/// i proporcionalno je skalira kada korisnik uveća font ([fontScale] > 1.0).
double computeMinTouchTarget({required bool compact, double fontScale = 1.0}) {
  final base = compact ? _minTouchTargetCompact : _minTouchTarget;
  final scaleMultiplier =
      fontScale > 1.0 ? (fontScale * 0.9).clamp(1.0, 1.4) : 1.0;
  return (base * scaleMultiplier).roundToDouble();
}

/// Helper funkcija za kreiranje shared button tema
ElevatedButtonThemeData _buildElevatedButtonTheme({
  required Size touch,
  required double buttonPaddingH,
  required double buttonPaddingV,
  required Color backgroundColor,
  required Color foregroundColor,
  required double borderRadius,
  double elevation = 2,
}) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      minimumSize: touch,
      padding: EdgeInsets.symmetric(
          horizontal: buttonPaddingH, vertical: buttonPaddingV),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      elevation: elevation,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return foregroundColor.withValues(alpha: 0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return foregroundColor.withValues(alpha: 0.05);
        }
        return null;
      }),
    ),
  );
}

TextButtonThemeData _buildTextButtonTheme({
  required Size touch,
  required double buttonPaddingH,
  required double buttonPaddingV,
  required Color foregroundColor,
  double borderRadius = 12,
}) {
  return TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: touch,
      padding: EdgeInsets.symmetric(
          horizontal: buttonPaddingH - 4, vertical: buttonPaddingV - 4),
      foregroundColor: foregroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
  );
}

OutlinedButtonThemeData _buildOutlinedButtonTheme({
  required Size touch,
  required double buttonPaddingH,
  required double buttonPaddingV,
  required Color borderColor,
  required Color foregroundColor,
  double borderWidth = 1.5,
  double borderRadius = 16,
}) {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: touch,
      padding: EdgeInsets.symmetric(
          horizontal: buttonPaddingH - 4, vertical: buttonPaddingV - 4),
      side: BorderSide(color: borderColor, width: borderWidth),
      foregroundColor: foregroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
  );
}

IconButtonThemeData _buildIconButtonTheme({
  required Size touch,
  required bool compact,
}) {
  return IconButtonThemeData(
    style: IconButton.styleFrom(
      minimumSize: touch,
      padding: EdgeInsets.all(compact ? 4 : 8),
    ),
  );
}

/// Tipografski sistem: Bitter (topli zanatski serif) za naslove —
/// Display / Headline / Title role nose identitet "nasleđa i sela",
/// dok Roboto ostaje sans podloga za Body / Label (čitljivost na
/// malim veličinama: cene, forme, dugmad, metapodaci).
TextTheme _buildTextTheme(TextTheme base, Brightness brightness) {
  final roboto = GoogleFonts.robotoTextTheme(base);
  final bitter = GoogleFonts.bitterTextTheme(base);
  return roboto.copyWith(
    // Display / Headline — Bitter (karakter i izražaj)
    displayLarge: GoogleFonts.bitter(textStyle: bitter.displayLarge)
        .copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.2),
    displayMedium: GoogleFonts.bitter(textStyle: bitter.displayMedium)
        .copyWith(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.2),
    displaySmall: GoogleFonts.bitter(textStyle: bitter.displaySmall)
        .copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.25, letterSpacing: -0.1),
    headlineLarge: GoogleFonts.bitter(textStyle: bitter.headlineLarge)
        .copyWith(fontSize: 18, fontWeight: FontWeight.w700, height: 1.25),
    headlineMedium: GoogleFonts.bitter(textStyle: bitter.headlineMedium)
        .copyWith(fontSize: 16, fontWeight: FontWeight.w700, height: 1.25),
    headlineSmall: GoogleFonts.bitter(textStyle: bitter.headlineSmall)
        .copyWith(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
    // Title — Bitter (serif naslovi dijaloga, sekcija i ekrana)
    titleLarge: GoogleFonts.bitter(textStyle: bitter.titleLarge)
        .copyWith(
      fontSize: 18, fontWeight: FontWeight.w700, height: 1.25,
    ),
    titleMedium: GoogleFonts.bitter(textStyle: bitter.titleMedium)
        .copyWith(
      fontSize: 15, fontWeight: FontWeight.w700, height: 1.3,
    ),
    titleSmall: GoogleFonts.bitter(textStyle: bitter.titleSmall)
        .copyWith(
      fontSize: 13, fontWeight: FontWeight.w600, height: 1.3,
    ),
    // Body — Roboto (gust, čitljiv sadržaj)
    bodyLarge: roboto.bodyLarge?.copyWith(fontSize: 15, height: 1.4),
    bodyMedium: roboto.bodyMedium?.copyWith(fontSize: 13, height: 1.4),
    bodySmall: roboto.bodySmall?.copyWith(fontSize: 11, height: 1.3),
    // Label — Roboto (dugmad, chipovi, metapodaci)
    labelLarge: roboto.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
    labelMedium: roboto.labelMedium?.copyWith(fontSize: 11),
    labelSmall: roboto.labelSmall?.copyWith(fontSize: 10, height: 1.2),
  );
}

ThemeData _buildBaseTheme({required bool compact, double fontScale = 1.0}) {
  // Kompaktan prikaz je podrazumevano uključen radi optimizacije prostora
  final minTarget =
      computeMinTouchTarget(compact: compact, fontScale: fontScale);
  final touch = Size.square(minTarget);
  final buttonPaddingV = compact ? AppDesign.spaceXS + 3 : AppDesign.spaceM;
  final buttonPaddingH = compact ? AppDesign.spaceM + 2 : AppDesign.spaceXL - 4;
  final listTilePaddingV = compact ? 0.0 : AppDesign.spaceXS;
  final listTileMinVerticalPadding = compact ? 2.0 : AppDesign.spaceS - 2;
  final inputPaddingV = compact ? AppDesign.spaceS : AppDesign.spaceM;
  final cardMarginV = compact ? 2.0 : AppDesign.spaceXS;
  final navBarHeight = compact ? 52.0 : 60.0;
  final visualDensity =
      compact ? VisualDensity.compact : VisualDensity.comfortable;

  return ThemeData(
    useMaterial3: true,
    visualDensity: visualDensity,
    iconTheme: const IconThemeData(
      size: 24,
      color: Color(0xFF37434F),
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF245938), // Topla šumska zelena (brend: AmazonColors.link)
      onPrimary: Colors.white,
      secondary: Color(0xFF2E7D32), // Prirodna livadska zelena (brend: AmazonColors.green)
      onSecondary: Colors.white,
      error: Color(0xFFD32F2F),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1B201C), // Topla ugljena (brend: AmazonColors.textPrimary)
      surfaceContainerHighest: Color(0xFFF1F4F1), // Veoma svetla zelena/siva
      onSurfaceVariant: Color(0xFF4A554D),
      outline: Color(0xFF72777F),
      shadow: Color(0xFF000000),
      inverseSurface: Color(0xFF2F3033),
      onInverseSurface: Color(0xFFF1F0F4),
      tertiary: Color(0xFF386567),
      onTertiary: Colors.white,
      primaryContainer: Color(0xFF386B41),
      onPrimaryContainer: Colors.white,
      secondaryContainer: Color(0xFFE4E9D6),
      onSecondaryContainer: Color(0xFF245938),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      toolbarHeight: 46,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1B201C),
      iconTheme: IconThemeData(color: Color(0xFF1B201C), size: 20),
      actionsIconTheme: IconThemeData(color: Color(0xFF1B201C), size: 20),
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: Color(0xFF1B201C),
      ),
      shape: Border(
        bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Color(0xFF245938),
      unselectedLabelColor: Color(0xFF555E57),
      indicatorColor: Color(0xFF245938),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Color(0xFFE5E7EB),
    ),
    elevatedButtonTheme: _buildElevatedButtonTheme(
      touch: touch,
      buttonPaddingH: buttonPaddingH,
      buttonPaddingV: buttonPaddingV,
      backgroundColor: const Color(0xFF245938),
      foregroundColor: Colors.white,
      borderRadius: 18,
    ),
    textButtonTheme: _buildTextButtonTheme(
      touch: touch,
      buttonPaddingH: buttonPaddingH,
      buttonPaddingV: buttonPaddingV,
      foregroundColor: const Color(0xFF245938),
    ),
    outlinedButtonTheme: _buildOutlinedButtonTheme(
      touch: touch,
      buttonPaddingH: buttonPaddingH,
      buttonPaddingV: buttonPaddingV,
      borderColor: const Color(0xFF245938),
      foregroundColor: const Color(0xFF245938),
    ),
    iconButtonTheme: _buildIconButtonTheme(
      touch: touch,
      compact: compact,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: listTilePaddingV),
      minLeadingWidth: 24,
      minVerticalPadding: listTileMinVerticalPadding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFCFD8DC),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFCFD8DC),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF245938),
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFD32F2F),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFD32F2F),
          width: 2.0,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9F8),
      errorStyle: const TextStyle(
        fontSize: 12,
        height: 1.3,
        color: Color(0xFFD32F2F),
      ),
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: inputPaddingV),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      modalElevation: 4,
      showDragHandle: true,
      constraints: BoxConstraints(maxWidth: Breakpoints.modalMaxWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDesign.radiusXL)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: AppDesign.spaceS, vertical: cardMarginV),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusL),
        side: BorderSide(color: const Color(0xFFE0E0E0).withValues(alpha: 0.6), width: 1),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.08),
    ),
    chipTheme: ChipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: AppDesign.spaceS, vertical: AppDesign.spaceXS),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusS)),
      backgroundColor: Colors.grey.shade100,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.fixed,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      contentTextStyle: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: Colors.white,
      ),
    ),
    bannerTheme: const MaterialBannerThemeData(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leadingPadding: EdgeInsets.only(right: 12),
      contentTextStyle: TextStyle(
        fontSize: 14,
        height: 1.4,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF2E7D32),
      unselectedItemColor: Color(0xFF757575),
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
    ),
    scrollbarTheme: const ScrollbarThemeData(
      thumbVisibility: WidgetStatePropertyAll(false),
      trackVisibility: WidgetStatePropertyAll(false),
      thickness: WidgetStatePropertyAll(0.0),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: navBarHeight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFF2E7D32), size: 26);
        }
        return const IconThemeData(color: Color(0xFF757575), size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            color: Color(0xFF2E7D32),
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
          color: Colors.grey,
        );
      }),
    ),
  );
}

ThemeData buildAppTheme({bool compact = false, double fontScale = 1.0}) {
  final base = _buildBaseTheme(compact: compact, fontScale: fontScale);
  final navBarHeight = compact ? 56.0 : 64.0;
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF8F6F0),
    canvasColor: Colors.white,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      toolbarHeight: compact ? 44.0 : 46.0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1B201C),
      iconTheme: const IconThemeData(color: Color(0xFF1B201C), size: 20),
      actionsIconTheme: const IconThemeData(color: Color(0xFF1B201C), size: 20),
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: const Color(0xFF1B201C),
      ),
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: const Color(0xFF245938),
      unselectedLabelColor: const Color(0xFF555E57),
      indicatorColor: const Color(0xFF245938),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: const Color(0xFFE5E7EB),
      labelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    textTheme: _buildTextTheme(
      ThemeData.light().textTheme,
      Brightness.light,
    ).apply(
      bodyColor: const Color(0xFF1B201C),
      displayColor: const Color(0xFF1B201C),
    ),
    colorScheme: base.colorScheme.copyWith(
      surface: Colors.white,
      onSurface: const Color(0xFF1B201C),
      onSurfaceVariant: const Color(0xFF4A554D),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF2E7D32),
      unselectedItemColor: Color(0xFF757575),
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: navBarHeight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFF2E7D32), size: 26);
        }
        return const IconThemeData(color: Color(0xFF424242), size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            color: Color(0xFF2E7D32),
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
          color: Color(0xFF757575),
        );
      }),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      hintStyle: const TextStyle(
        color: Color(0xFF78909C),
        height: 1.3,
      ),
      labelStyle: const TextStyle(color: Color(0xFF37434F)),
    ),
  );
}

ThemeData buildAppDarkTheme({bool compact = false, double fontScale = 1.0}) {
  final minTarget =
      computeMinTouchTarget(compact: compact, fontScale: fontScale);
  final touch = Size.square(minTarget);
  final buttonPaddingV = compact ? 7.0 : 12.0;
  final buttonPaddingH = compact ? 14.0 : 20.0;
  final inputPaddingV = compact ? 8.0 : 12.0;
  final navBarHeight = compact ? 52.0 : 60.0;
  final visualDensity =
      compact ? VisualDensity.compact : VisualDensity.comfortable;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    visualDensity: visualDensity,
    scaffoldBackgroundColor: const Color(0xFF121714),
    canvasColor: const Color(0xFF1B241E),
    textTheme: _buildTextTheme(
      ThemeData.dark().textTheme,
      Brightness.dark,
    ).apply(
      bodyColor: const Color(0xFFECEFF1),
      displayColor: const Color(0xFFF5F5F5),
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFE89844), // Topli medeni ćilibar (brend: AmazonColors.amberLight)
      onPrimary: Color(0xFF142419),
      secondary: Color(0xFF81C784), // Svetlo zelena (brend: AmazonColors.lightGreen)
      onSecondary: Color(0xFF142419),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      surface: Color(0xFF1A1C19), // Tamno siva sa zelenim tonom
      onSurface: Color(0xFFE2E3DD),
      surfaceContainerHighest: Color(0xFF424940),
      onSurfaceVariant: Color(0xFFD0D6CB), // Malo svetlije za bolji kontrast (WCAG AA)
      outline: Color(0xFF8C9388),
      shadow: Colors.black,
      inverseSurface: Color(0xFFE2E3DD),
      onInverseSurface: Color(0xFF1A1C19),
      tertiary: Color(0xFFE89844),
      onTertiary: Color(0xFF142419),
      primaryContainer: Color(0xFF005223),
      onPrimaryContainer: Color(0xFFE89844), // Topli kontrast za sitan tekst
      secondaryContainer: Color(0xFF386B41),
      onSecondaryContainer: Color(0xFFE89844),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      toolbarHeight: compact ? 44.0 : 46.0,
      backgroundColor: const Color(0xFF1A1C19),
      foregroundColor: const Color(0xFFE2E3DD),
      iconTheme: const IconThemeData(color: Color(0xFFE2E3DD), size: 20),
      actionsIconTheme: const IconThemeData(color: Color(0xFFE2E3DD), size: 20),
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: const Color(0xFFE2E3DD),
      ),
      shape: const Border(
        bottom: BorderSide(color: Color(0xFF2F3033), width: 1),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: const Color(0xFFD0D6CB),
      indicatorColor: const Color(0xFFE89844),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: const Color(0xFF2F3033),
      labelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: _buildElevatedButtonTheme(
      touch: touch,
      buttonPaddingH: buttonPaddingH,
      buttonPaddingV: buttonPaddingV,
      backgroundColor: const Color(0xFFE89844),
      foregroundColor: const Color(0xFF142419),
      borderRadius: 12,
    ),
    textButtonTheme: _buildTextButtonTheme(
      touch: touch,
      buttonPaddingH: buttonPaddingH,
      buttonPaddingV: buttonPaddingV,
      foregroundColor: const Color(0xFFE89844),
    ),
    outlinedButtonTheme: _buildOutlinedButtonTheme(
      touch: touch,
      buttonPaddingH: buttonPaddingH,
      buttonPaddingV: buttonPaddingV,
      borderColor: const Color(0xFFE89844),
      foregroundColor: const Color(0xFFE89844),
    ),
    iconButtonTheme: _buildIconButtonTheme(
      touch: touch,
      compact: compact,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: inputPaddingV),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1B241E),
      surfaceTintColor: Colors.transparent,
      modalElevation: 4,
      showDragHandle: true,
      constraints: BoxConstraints(maxWidth: Breakpoints.modalMaxWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDesign.radiusXL)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 3 : 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 2 : 8),
      minLeadingWidth: 24,
      minVerticalPadding: compact ? 4 : 10,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFFE89844),
      unselectedItemColor: Color(0xFF8C9388),
      type: BottomNavigationBarType.fixed,
    ),
    scrollbarTheme: const ScrollbarThemeData(
      thumbVisibility: WidgetStatePropertyAll(false),
      trackVisibility: WidgetStatePropertyAll(false),
      thickness: WidgetStatePropertyAll(0.0),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: navBarHeight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: const Color(0xFFE89844).withValues(alpha: 0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFFE89844), size: 26);
        }
        return const IconThemeData(color: Color(0xFF8C9388), size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE89844),
          );
        }
        return const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Color(0xFF8C9388),
        );
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return const Color(0xFFCBD5E1);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF2E7D32);
        }
        return const Color(0xFF334155);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return const Color(0xFF64748B);
      }),
    ),
  );
}

// Backward-compatible static instances (non-compact).
final ThemeData appTheme = buildAppTheme();
final ThemeData appDarkTheme = buildAppDarkTheme();
