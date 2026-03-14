import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyThemeMode = 'mleko_theme_mode'; // 0=system, 1=light, 2=dark
const _keyAnimationsEnabled = 'mleko_animations_enabled';
const _keyFontScale = 'mleko_font_scale';

class AppSettingsProvider extends ChangeNotifier {
  /// Dostupne vrednosti za razmeru fonta (koristi se kao TextScaler.linear(fontScale)).
  static const double fontScaleMin = 0.9;
  static const double fontScaleMax = 1.5;
  static const List<double> fontScalePresets = [0.9, 1.0, 1.15, 1.3, 1.5];

  ThemeMode _themeMode = ThemeMode.system;
  bool _animationsEnabled = true;
  double _fontScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  bool get animationsEnabled => _animationsEnabled;
  double get fontScale => _fontScale.clamp(fontScaleMin, fontScaleMax);

  bool get isDarkTheme {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return false; // caller should use MediaQuery.platformBrightness
    }
  }

  AppSettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeMode = _themeModeFromInt(prefs.getInt(_keyThemeMode) ?? 0);
      _animationsEnabled = prefs.getBool(_keyAnimationsEnabled) ?? true;
      _fontScale = prefs.getDouble(_keyFontScale) ?? 1.0;
      if (_fontScale < fontScaleMin || _fontScale > fontScaleMax) {
        _fontScale = 1.0;
      }
      notifyListeners();
    } catch (_) {
      // keep defaults
    }
  }

  static ThemeMode _themeModeFromInt(int v) {
    switch (v) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static int _themeModeToInt(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      case ThemeMode.system:
        return 0;
    }
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyThemeMode, _themeModeToInt(value));
    } catch (_) {}
  }

  Future<void> setAnimationsEnabled(bool value) async {
    if (_animationsEnabled == value) return;
    _animationsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAnimationsEnabled, value);
    } catch (_) {}
  }

  Future<void> setFontScale(double value) async {
    final clamped = value.clamp(fontScaleMin, fontScaleMax);
    if (_fontScale == clamped) return;
    _fontScale = clamped;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyFontScale, clamped);
    } catch (_) {}
  }
}
