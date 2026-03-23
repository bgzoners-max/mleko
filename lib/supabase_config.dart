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

  static String get url => kIsWeb
      ? const String.fromEnvironment('SUPABASE_URL')
      : dotenv.env['SUPABASE_URL'] ??
          (throw Exception('❌ Missing SUPABASE_URL in .env'));

  static String get anonKey => kIsWeb
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : dotenv.env['SUPABASE_ANON_KEY'] ??
          (throw Exception('❌ Missing SUPABASE_ANON_KEY in .env'));

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Base URL za share links (deep links, web). Default trenutni origin.
  static String get shareBaseUrl => kIsWeb
      ? const String.fromEnvironment('SHARE_BASE_URL', defaultValue: '')
      : dotenv.env['SHARE_BASE_URL'] ?? '';

  /// Load .env - pozovi pre Supabase.initialize()
  static Future<void> load() async {
    if (kIsWeb) {
      if (!isConfigured) {
        throw Exception(
            '❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
            'Build with: flutter build web '
            '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...');
      }
    } else {
      await dotenv.load(fileName: '.env');
      if (!isConfigured) {
        throw Exception('Supabase config missing in .env - see .env.example');
      }
    }
  }
}
