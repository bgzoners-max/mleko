import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/app_error.dart';

/// Supabase konfiguracija iz .env fajla.
class SupabaseConfig {
  SupabaseConfig._();

  static const String _defaultUrl = 'https://wvqtujpurhzraptorcvl.supabase.co';
  static const String _defaultAnonKey =
      'sb_publishable_fctLgkfcyV3HtMIHkO6lvw_NdmiBrsX';

  static String get _urlFromDefine =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: _defaultUrl);

  static String get _anonKeyFromDefine =>
      const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: _defaultAnonKey);

  static String get _shareBaseUrlFromDefine => const String.fromEnvironment(
      'SHARE_BASE_URL',
      defaultValue: 'https://domacimarket.rs');

  static String get url => _urlFromDefine.isNotEmpty
      ? _urlFromDefine
      : dotenv.env['SUPABASE_URL'] ?? _defaultUrl;

  static String get anonKey => _anonKeyFromDefine.isNotEmpty
      ? _anonKeyFromDefine
      : dotenv.env['SUPABASE_ANON_KEY'] ?? _defaultAnonKey;

  /// Alias za publishableKey u skladu sa novijim Supabase SDK-om
  static String get publishableKey => anonKey;

  /// Provera da li je konfiguracija prisutna — bez barijanja greške.
  static bool get isConfigured {
    final u = _urlFromDefine.isNotEmpty
        ? _urlFromDefine
        : dotenv.env['SUPABASE_URL'];
    final k = _anonKeyFromDefine.isNotEmpty
        ? _anonKeyFromDefine
        : dotenv.env['SUPABASE_ANON_KEY'];
    return u != null && u.isNotEmpty && k != null && k.isNotEmpty;
  }

  /// Base URL za share links (deep links, web). Default trenutni origin.
  static String get shareBaseUrl => _shareBaseUrlFromDefine.isNotEmpty
      ? _shareBaseUrlFromDefine
      : dotenv.env['SHARE_BASE_URL'] ?? '';

  /// Load .env - pozovi pre Supabase.initialize()
  static Future<void> load() async {
    // If --dart-define values are present, skip .env loading entirely.
    if (_urlFromDefine.isNotEmpty && _anonKeyFromDefine.isNotEmpty) return;

    try {
      await dotenv.load(fileName: 'assets/.env');
    } catch (e) {
      // Ignorisemo gresku ako fajl ne postoji, oslanjamo se na --dart-define
    }

    if (!kIsWeb &&
        _urlFromDefine.isEmpty &&
        (dotenv.env['SUPABASE_URL'] == null ||
            dotenv.env['SUPABASE_ANON_KEY'] == null)) {
      throw AppError(
        message: 'Supabase config missing',
        userMessage: 'Podesavanja za Supabase nedostaju. Koristite --dart-define ili assets/.env fajl.',
        type: ErrorType.configuration,
      );
    }
  }
}
