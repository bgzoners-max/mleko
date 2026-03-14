import 'package:flutter/material.dart';

const Size _minTouchTarget = Size(48, 48);

final ThemeData _baseTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32),
    brightness: Brightness.light,
    primary: const Color(0xFF2E7D32),
    secondary: const Color(0xFF8BC34A),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Color(0xFF2E7D32),
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
    selectedItemColor: Color(0xFF2E7D32),
    unselectedItemColor: Colors.grey,
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
      return const IconThemeData(color: Colors.grey, size: 24);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E7D32),
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

final ThemeData appTheme = _baseTheme.copyWith(
  textTheme: _baseTheme.textTheme
      .copyWith(
        titleLarge: _baseTheme.textTheme.titleLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: _baseTheme.textTheme.titleMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: _baseTheme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
        ),
      )
      .apply(
        bodyColor: const Color(0xFF111111),
        displayColor: const Color(0xFF111111),
      ),
  colorScheme: _baseTheme.colorScheme.copyWith(
    onSurface: const Color(0xFF111111),
    onSurfaceVariant: const Color(0xFF5C6A7D),
  ),
);

/// Tamna tema (ista paleta, brightness dark).
final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32),
    brightness: Brightness.dark,
    primary: const Color(0xFF81C784),
    secondary: const Color(0xFF8BC34A),
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
