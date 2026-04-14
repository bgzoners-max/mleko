import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase konfiguracija iz .env fajla.
///
/// 1. Kreiraj .env iz .env.example i popuni SUPABASE_URL / ANON_KEY
/// 2. flutter pub get
/// 3. flutter run (dotenv auto-loads .env iz assets)
///
/// Kreiraj projekat: https://supabase.com/dashboard → Settings → API
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
          (throw Exception(
              'Missing SUPABASE_URL. Provide it via .env or --dart-define.'));

  static String get anonKey => _anonKeyFromDefine.isNotEmpty
      ? _anonKeyFromDefine
      : dotenv.env['SUPABASE_ANON_KEY'] ??
          (throw Exception(
              'Missing SUPABASE_ANON_KEY. Provide it via .env or --dart-define.'));

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

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

    if (_urlFromDefine.isEmpty &&
        (dotenv.env['SUPABASE_URL'] == null ||
            dotenv.env['SUPABASE_ANON_KEY'] == null)) {
      throw Exception(kIsWeb
          ? 'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
              'Provide them in .env or build with '
              '--dart-define=SUPABASE_URL=... '
              '--dart-define=SUPABASE_ANON_KEY=...'
          : 'Supabase config missing in .env - see .env.example');
    }
  }
}
