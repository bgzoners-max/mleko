import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Size _minTouchTarget = Size(48, 48);
const Size _minTouchTargetCompact = Size(40, 40);

/// Source Sans 3 – čitljiv, moderan font za body tekst.
/// Nunito – zaobljen, prijatan za naslove (display).
TextTheme _buildTextTheme(TextTheme base, Brightness brightness) {
  final sourceSans = GoogleFonts.sourceSans3TextTheme(base);
  return sourceSans.copyWith(
    // H1 / H2 / H3 – jasna hijerarhija naslova
    displayLarge: GoogleFonts.nunito(
      textStyle: sourceSans.displayLarge,
    ).copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    displayMedium: GoogleFonts.nunito(
      textStyle: sourceSans.displayMedium,
    ).copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    displaySmall: GoogleFonts.nunito(
      textStyle: sourceSans.displaySmall,
    ).copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineLarge: GoogleFonts.nunito(
      textStyle: sourceSans.headlineLarge,
    ).copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineMedium: GoogleFonts.nunito(
      textStyle: sourceSans.headlineMedium,
    ).copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineSmall: GoogleFonts.nunito(
      textStyle: sourceSans.headlineSmall,
    ).copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleLarge: sourceSans.titleLarge?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    titleMedium: sourceSans.titleMedium?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    bodyLarge: sourceSans.bodyLarge?.copyWith(
      fontSize: 16,
      height: 1.4,
    ),
    bodyMedium: sourceSans.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.4,
    ),
    bodySmall: sourceSans.bodySmall?.copyWith(
      fontSize: 12,
      height: 1.3,
    ),
    labelSmall: sourceSans.labelSmall?.copyWith(
      fontSize: 11,
      height: 1.3,
    ),
  );
}

ThemeData _buildBaseTheme({required bool compact}) {
  final touch = compact ? _minTouchTargetCompact : _minTouchTarget;
  final buttonPaddingV = compact ? 8.0 : 14.0;
  final buttonPaddingH = compact ? 16.0 : 24.0;
  final listTilePaddingV = compact ? 2.0 : 8.0;
  final listTileMinVerticalPadding = compact ? 4.0 : 10.0;
  final inputPaddingV = compact ? 10.0 : 14.0;
  final cardMarginV = compact ? 3.0 : 6.0;
  final navBarHeight = compact ? 56.0 : 64.0;
  final visualDensity =
      compact ? VisualDensity.compact : VisualDensity.standard;

  return ThemeData(
    useMaterial3: true,
    visualDensity: visualDensity,
    iconTheme: const IconThemeData(
      size: 24,
      color: Color(0xFF37434F),
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1B5E20), // tamnija, jači kontrast
      onPrimary: Colors.white,
      secondary: Color(0xFF8BC34A),
      onSecondary: Colors.black,
      error: Color(0xFFD32F2F),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF0A0A0A),
      surfaceContainerHighest: Color(0xFFE0E0E0),
      onSurfaceVariant: Color(0xFF37434F),
      outline: Color(0xFFB0BEC5),
      shadow: Colors.black54,
      inverseSurface: Color(0xFF263238),
      onInverseSurface: Colors.white,
      tertiary: Color(0xFF8BC34A),
      onTertiary: Colors.black,
      primaryContainer: Color(0xFF2E7D32),
      onPrimaryContainer: Colors.white,
      secondaryContainer: Color(0xFFC5E1A5),
      onSecondaryContainer: Color(0xFF263238),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: Colors.white,
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      indicatorColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        minimumSize: touch,
        padding: EdgeInsets.symmetric(
            horizontal: buttonPaddingH, vertical: buttonPaddingV),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFF1B5E20).withValues(alpha: 0.2);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF2E7D32).withValues(alpha: 0.08);
          }
          return null;
        }),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 0;
          if (states.contains(WidgetState.hovered)) return 3;
          return 1;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: touch,
        padding: EdgeInsets.symmetric(
            horizontal: buttonPaddingH - 4, vertical: buttonPaddingV - 4),
        foregroundColor: const Color(0xFF2E7D32),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFF2E7D32).withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF2E7D32).withValues(alpha: 0.06);
          }
          return null;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: touch,
        padding: EdgeInsets.symmetric(
            horizontal: buttonPaddingH - 4, vertical: buttonPaddingV - 4),
        side: const BorderSide(color: Color(0xFF2E7D32)),
        foregroundColor: const Color(0xFF2E7D32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFF2E7D32).withValues(alpha: 0.10);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF2E7D32).withValues(alpha: 0.05);
          }
          return null;
        }),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: touch,
        padding: EdgeInsets.all(compact ? 4 : 8),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.black.withValues(alpha: 0.06);
          }
          return null;
        }),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: listTilePaddingV),
      minLeadingWidth: 24,
      minVerticalPadding: listTileMinVerticalPadding,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFCFD8DC),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFCFD8DC),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF2E7D32),
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD32F2F),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD32F2F),
          width: 1.6,
        ),
      ),
      filled: true,
      errorStyle: const TextStyle(
        fontSize: 12,
        height: 1.3,
        color: Color(0xFFD32F2F),
      ),
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: inputPaddingV),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: cardMarginV),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withValues(alpha: 0.12),
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
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.all(true),
      trackVisibility: WidgetStateProperty.all(true),
      interactive: true,
      thickness: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return 12.0;
        return 8.0;
      }),
      radius: const Radius.circular(8),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFF2E7D32).withValues(alpha: 0.8);
        }
        return Colors.grey.withValues(alpha: 0.4);
      }),
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

ThemeData buildAppTheme({bool compact = false}) {
  final base = _buildBaseTheme(compact: compact);
  final navBarHeight = compact ? 56.0 : 64.0;
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    canvasColor: Colors.white,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: Colors.white,
      ),
    ),
    textTheme: _buildTextTheme(
      ThemeData.light().textTheme,
      Brightness.light,
    ).apply(
      bodyColor: const Color(0xFF0A0A0A),
      displayColor: const Color(0xFF0A0A0A),
    ),
    colorScheme: base.colorScheme.copyWith(
      surface: Colors.white,
      onSurface: const Color(0xFF0A0A0A),
      onSurfaceVariant: const Color(0xFF37434F),
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

ThemeData buildAppDarkTheme({bool compact = false}) {
  final touch = compact ? _minTouchTargetCompact : _minTouchTarget;
  final buttonPaddingV = compact ? 8.0 : 14.0;
  final buttonPaddingH = compact ? 16.0 : 24.0;
  final inputPaddingV = compact ? 10.0 : 14.0;
  final navBarHeight = compact ? 56.0 : 64.0;
  final visualDensity =
      compact ? VisualDensity.compact : VisualDensity.standard;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    visualDensity: visualDensity,
    scaffoldBackgroundColor: const Color(0xFF121212),
    canvasColor: const Color(0xFF1E1E1E),
    textTheme: _buildTextTheme(
      ThemeData.dark().textTheme,
      Brightness.dark,
    ).apply(
      bodyColor: const Color(0xFFECEFF1),
      displayColor: const Color(0xFFF5F5F5),
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF99D19C), // Lakša zelena za tamni režim
      onPrimary: Color(0xFF003916),
      secondary: Color(0xFFB9F6CA),
      onSecondary: Color(0xFF003916),
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
      tertiary: Color(0xFFB9F6CA),
      onTertiary: Color(0xFF003916),
      primaryContainer: Color(0xFF005223),
      onPrimaryContainer: Color(0xFFC8FFC6), // Unapređen kontrast za sitan tekst
      secondaryContainer: Color(0xFF386B41),
      onSecondaryContainer: Color(0xFFB9F6CA),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF1A1C19),
      foregroundColor: Color(0xFFE2E3DD),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF99D19C),
        foregroundColor: const Color(0xFF003916),
        minimumSize: touch,
        padding: EdgeInsets.symmetric(
            horizontal: buttonPaddingH, vertical: buttonPaddingV),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: touch),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: touch),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: touch),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: inputPaddingV),
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
      selectedItemColor: Color(0xFF99D19C),
      unselectedItemColor: Color(0xFF8C9388),
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: navBarHeight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: const Color(0xFF99D19C).withValues(alpha: 0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFF99D19C), size: 26);
        }
        return const IconThemeData(color: Color(0xFF8C9388), size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF99D19C),
          );
        }
        return const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Color(0xFF8C9388),
        );
      }),
    ),
  );
}

// Backward-compatible static instances (non-compact).
final ThemeData appTheme = buildAppTheme();
final ThemeData appDarkTheme = buildAppDarkTheme();
