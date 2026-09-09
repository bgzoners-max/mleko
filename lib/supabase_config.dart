import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/app_error.dart';

/// Supabase konfiguracija iz .env fajla.
class SupabaseConfig {
  SupabaseConfig._();

  static String get _urlFromDefine =>
      const String.fromEnvironment('SUPABASE_URL');

  static String get _anonKeyFromDefine =>
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get _shareBaseUrlFromDefine =>
      const String.fromEnvironment('SHARE_BASE_URL', defaultValue: '');

  static String get url => _urlFromDefine.isNotEmpty
      ? _urlFromDefine
      : dotenv.env['SUPABASE_URL'] ??
          (throw AppError(
            message: 'Missing SUPABASE_URL',
            userMessage: 'Nedostaje SUPABASE_URL u podešavanjima.',
            type: ErrorType.configuration,
          ));

  static String get anonKey => _anonKeyFromDefine.isNotEmpty
      ? _anonKeyFromDefine
      : dotenv.env['SUPABASE_ANON_KEY'] ??
          (throw AppError(
            message: 'Missing SUPABASE_ANON_KEY',
            userMessage: 'Nedostaje SUPABASE_ANON_KEY u podešavanjima.',
            type: ErrorType.configuration,
          ));

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
      // Web preview builds may rely on --dart-define instead of the bundled .env asset.
      if (!kIsWeb) rethrow;
    }

    if (!kIsWeb &&
        _urlFromDefine.isEmpty &&
        (dotenv.env['SUPABASE_URL'] == null ||
            dotenv.env['SUPABASE_ANON_KEY'] == null)) {
      throw AppError(
        message: 'Supabase config missing in .env',
        userMessage: 'Podešavanja za Supabase nedostaju u .env fajlu.',
        type: ErrorType.configuration,
      );
    }
  }
}
