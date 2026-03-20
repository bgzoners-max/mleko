import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Size _minTouchTarget = Size(48, 48);

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

final ThemeData _baseTheme = ThemeData(
  useMaterial3: true,
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
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2E7D32), // primarni CTA
      foregroundColor: Colors.white,
      minimumSize: _minTouchTarget,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
      minimumSize: _minTouchTarget,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      minimumSize: _minTouchTarget,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      minimumSize: _minTouchTarget,
      padding: const EdgeInsets.all(8),
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
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    minLeadingWidth: 24,
    minVerticalPadding: 10,
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    shadowColor: Colors.black.withValues(alpha: 0.12),
  ),
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
  navigationBarTheme: NavigationBarThemeData(
    height: 64,
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

final ThemeData appTheme = _baseTheme.copyWith(
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  canvasColor: Colors.white,
  textTheme: _buildTextTheme(
    ThemeData.light().textTheme,
    Brightness.light,
  ).apply(
    bodyColor: const Color(0xFF0A0A0A),
    displayColor: const Color(0xFF0A0A0A),
  ),
  colorScheme: _baseTheme.colorScheme.copyWith(
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
    height: 64,
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
  inputDecorationTheme: _baseTheme.inputDecorationTheme.copyWith(
    hintStyle: const TextStyle(
      color: Color(0xFF78909C),
      height: 1.3,
    ),
    labelStyle: const TextStyle(color: Color(0xFF37434F)),
  ),
);

/// Tamna tema (ista paleta, brightness dark).
final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
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
    primary: Color(0xFF81C784),
    onPrimary: Color(0xFF003314),
    secondary: Color(0xFF8BC34A),
    onSecondary: Color(0xFF102027),
    error: Color(0xFFEF5350),
    onError: Color(0xFF1B0000),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFECEFF1),
    surfaceContainerHighest: Color(0xFF263238),
    onSurfaceVariant: Color(0xFFB0BEC5),
    outline: Color(0xFF546E7A),
    shadow: Colors.black,
    inverseSurface: Color(0xFFECEFF1),
    onInverseSurface: Color(0xFF121212),
    tertiary: Color(0xFF8BC34A),
    onTertiary: Color(0xFF102027),
    primaryContainer: Color(0xFF33691E),
    onPrimaryContainer: Color(0xFFE8F5E9),
    secondaryContainer: Color(0xFF558B2F),
    onSecondaryContainer: Color(0xFFF1F8E9),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Color(0xFF1B5E20),
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      minimumSize: _minTouchTarget,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(minimumSize: _minTouchTarget),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(minimumSize: _minTouchTarget),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(minimumSize: _minTouchTarget),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: Color(0xFF81C784),
    unselectedItemColor: Colors.grey,
    type: BottomNavigationBarType.fixed,
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 64,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    indicatorColor: const Color(0xFF81C784).withValues(alpha: 0.2),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: Color(0xFF81C784), size: 26);
      }
      return const IconThemeData(color: Colors.grey, size: 24);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF81C784),
        );
      }
      return const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: Colors.grey,
      );
    }),
  ),
);
