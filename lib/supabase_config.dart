/// Supabase konfiguracija sa podrazumevanim vrednostima i podrškom za --dart-define override.
class SupabaseConfig {
  SupabaseConfig._();

  static const String _defaultUrl = 'https://wvqtujpurhzraptorcvl.supabase.co';
  static const String _defaultAnonKey =
      'sb_publishable_fctLgkfcyV3HtMIHkO6lvw_NdmiBrsX';
  static const String _defaultShareBaseUrl = 'https://domacimarket.rs';

  static String get url => const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: _defaultUrl,
      );

  static String get anonKey => const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: _defaultAnonKey,
      );

  /// Alias za publishableKey u skladu sa novijim Supabase SDK-om
  static String get publishableKey => anonKey;

  /// Base URL za share links (deep links, web).
  static String get shareBaseUrl => const String.fromEnvironment(
        'SHARE_BASE_URL',
        defaultValue: _defaultShareBaseUrl,
      );

  /// Provera da li je konfiguracija prisutna.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Zadržano radi kompatibilnosti postojećih poziva u main.dart i background servisima.
  static Future<void> load() async {}
}
