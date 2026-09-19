/// Supabase konfiguracija sa podrazumevanim vrednostima i podrškom za --dart-define override.
///
/// Kanonski (jedini) javni domen brenda je `https://domacimarket.rs` — na njega je
/// aliasovan produkcijski Vercel deploy. `shareBaseUrl` služi za generisanje share/deep
/// linkova i mora uvek da odgovara tom domenu (ili produkcijskom domenu po okruženju).
/// `.env` fajl u korenu je ZASTAREO i NIJE izvor konfiguracije — aplikacija isključivo
/// čita vrednosti iz `--dart-define` (ovde `String.fromEnvironment`) ili ove подrazumevane.
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
}
