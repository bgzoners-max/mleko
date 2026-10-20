import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/core/logger_service.dart';
import '../widgets/home/market_mode_switcher.dart';
export '../widgets/home/market_mode_switcher.dart' show MarketMode;

const _keyThemeMode = 'mleko_theme_mode'; // 0=system, 1=light, 2=dark
const _keyAnimationsEnabled = 'mleko_animations_enabled';
const _keyFontScale = 'mleko_font_scale';
const _keyCompactMode = 'mleko_compact_mode';
const _keyMarketMode = 'mleko_market_mode_v2'; // 0=foodMarket, 1=classifieds
const _keyBetaNoticeDismissed = 'mleko_beta_notice_dismissed_v1';

/// Jednom se postavi na `true` nakon što su početne vrednosti (prva instalacija
/// ili migracija sa starije verzije) upisane u SharedPreferences. Posle toga se
/// uvek učitavaju samo sačuvane vrednosti — korisnički izbor se ne prepisuje.
const _keyInstallDefaultsBootstrap = 'mleko_install_defaults_bootstrap';

class AppSettingsProvider extends ChangeNotifier {
  /// Dostupne vrednosti za razmeru fonta (koristi se kao TextScaler.linear(fontScale)).
  static const double fontScaleMin = 0.9;
  static const double fontScaleMax = 1.5;
  static const List<double> fontScalePresets = [0.9, 1.0, 1.15, 1.3, 1.5];

  /// Neutralno stanje dok se async `_load()` ne završi (izbegava pogrešan prvi frejm).
  ThemeMode _themeMode = ThemeMode.system;
  bool _animationsEnabled = true;
  double _fontScale = 1.0;
  bool _compactMode = true;
  MarketMode _marketMode = MarketMode.foodMarket;
  bool _betaNoticeDismissed = false;

  ThemeMode get themeMode => _themeMode;
  bool get animationsEnabled => _animationsEnabled;
  double get fontScale => _fontScale.clamp(fontScaleMin, fontScaleMax);
  bool get compactMode => _compactMode;
  MarketMode get marketMode => _marketMode;
  bool get betaNoticeDismissed => _betaNoticeDismissed;

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

  bool _isLoaded = false;
  Future<void>? _loadFuture;

  bool get isLoaded => _isLoaded;

  AppSettingsProvider({bool autoload = true}) {
    if (autoload) {
      _loadFuture = _load();
    }
  }

  /// Eksplicitno čekanje da se settings učitaju (za pre prvog frejma i splash)
  Future<void> ensureLoaded() => _loadFuture ??= _load();

  /// Ključevi koji ukazuju da je aplikacija već korišćena pre ovog bootstrap-a
  /// (nadogradnja sa starije verzije). Namerno **ne** uključujemo `mleko_cache_*`
  /// da ne bi keš upisan u prvom frejmu pogrešno tretirao „starog“ korisnika.
  static bool _hasPriorAppUsage(SharedPreferences prefs) {
    const knownKeys = <String>[
      _keyThemeMode,
      _keyFontScale,
      _keyAnimationsEnabled,
      'mleko_selected_region',
      'mleko_search_history',
      'mleko_cart',
      'mleko_seller_drafts',
      'mleko_pending_orders',
      'mleko_cart_ids',
    ];
    for (final k in knownKeys) {
      if (prefs.containsKey(k)) return true;
    }
    for (final k in prefs.getKeys()) {
      if (k.startsWith('mleko_sync_analytics_')) return true;
    }
    return false;
  }

  Future<void> _persistBootstrapState(SharedPreferences prefs) async {
    await prefs.setInt(_keyThemeMode, _themeModeToInt(_themeMode));
    await prefs.setDouble(_keyFontScale, fontScale);
    await prefs.setBool(_keyAnimationsEnabled, _animationsEnabled);
    await prefs.setBool(_keyCompactMode, _compactMode);
    await prefs.setInt(_keyMarketMode, _marketModeToInt(_marketMode));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('mleko_market_mode')) {
        await prefs.remove('mleko_market_mode');
      }
      final bootstrapDone =
          prefs.getBool(_keyInstallDefaultsBootstrap) ?? false;

      if (!bootstrapDone) {
        if (_hasPriorAppUsage(prefs)) {
          // Nadogradnja: stare vrednosti, compact=false ako nije eksplicitno upisano.
          _readFromPrefs(prefs, defaultTheme: 0, defaultFont: 1.0, defaultCompact: false);
        } else {
          // Prva instalacija: svetla tema + normalan font + kompaktan prikaz.
          _themeMode = ThemeMode.light;
          _fontScale = 1.0;
          _compactMode = true;
        }
        await _persistBootstrapState(prefs);
        await prefs.setBool(_keyInstallDefaultsBootstrap, true);
      } else {
        // Samo sacuvano stanje (fallback ako je kljuc ostecen).
        _readFromPrefs(prefs, defaultTheme: 1, defaultFont: 1.0, defaultCompact: true);
      }

      // Finalna sinhronizacija internog stanja sa dozvoljenim granicama
      _fontScale = fontScale;
    } catch (_) {
      // keep field defaults
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  void _readFromPrefs(SharedPreferences prefs,
      {required int defaultTheme, required double defaultFont, bool defaultCompact = true}) {
    _themeMode = _themeModeFromInt(prefs.getInt(_keyThemeMode) ?? defaultTheme);
    _fontScale = prefs.getDouble(_keyFontScale) ?? defaultFont;
    _animationsEnabled = prefs.getBool(_keyAnimationsEnabled) ?? true;
    _compactMode = prefs.getBool(_keyCompactMode) ?? defaultCompact;
    _marketMode = _marketModeFromInt(prefs.getInt(_keyMarketMode) ?? 0);
    _betaNoticeDismissed = prefs.getBool(_keyBetaNoticeDismissed) ?? false;
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
    } catch (e) {
      LoggerService.warning('Failed to save theme mode',
          extra: {'error': e.toString()});
    }
  }

  Future<void> toggleTheme(BuildContext context) async {
    final isDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setAnimationsEnabled(bool value) async {
    if (_animationsEnabled == value) return;
    _animationsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAnimationsEnabled, value);
    } catch (e) {
      LoggerService.warning('Failed to save animations setting',
          extra: {'error': e.toString()});
    }
  }

  Future<void> setFontScale(double value) async {
    final clamped = value.clamp(fontScaleMin, fontScaleMax);
    if (_fontScale == clamped) return;
    _fontScale = clamped;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyFontScale, clamped);
    } catch (e) {
      LoggerService.warning('Failed to save font scale',
          extra: {'error': e.toString()});
    }
  }

  Future<void> setCompactMode(bool value) async {
    if (_compactMode == value) return;
    _compactMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyCompactMode, value);
    } catch (e) {
      LoggerService.warning('Failed to save compact mode',
          extra: {'error': e.toString()});
    }
  }

  Future<void> setMarketMode(MarketMode value) async {
    if (_marketMode == value) return;
    _marketMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyMarketMode, _marketModeToInt(value));
    } catch (e) {
      LoggerService.warning('Failed to save market mode',
          extra: {'error': e.toString()});
    }
  }

  static MarketMode _marketModeFromInt(int v) =>
      v == 1 ? MarketMode.classifieds : MarketMode.foodMarket;

  static int _marketModeToInt(MarketMode m) =>
      m == MarketMode.classifieds ? 1 : 0;

  Future<void> dismissBetaNotice() async {
    if (_betaNoticeDismissed) return;
    _betaNoticeDismissed = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBetaNoticeDismissed, true);
    } catch (e) {
      LoggerService.warning('Failed to save beta notice dismissed state',
          extra: {'error': e.toString()});
    }
  }

  Future<void> resetBetaNotice() async {
    if (!_betaNoticeDismissed) return;
    _betaNoticeDismissed = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyBetaNoticeDismissed);
    } catch (e) {
      LoggerService.warning('Failed to reset beta notice state',
          extra: {'error': e.toString()});
    }
  }
}
