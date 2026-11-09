/// Supabase konfiguracija sa podrškom za višestruka okruženja (`local`, `staging`, `prod`)
/// preko `--dart-define=APP_ENV=...` i pojedinačne varijable (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SHARE_BASE_URL`).
///
/// Kanonski javni domen produkcije je `https://www.domacimarket.rs`.
///
/// Bezbednost i izolacija:
/// - Za rad sa bazom parametri se prosleđuju preko `--dart-define` ili `--dart-define-from-file=config/prod.json`.
/// - Za lokalni razvoj koristi se `--dart-define=APP_ENV=local` ili `--dart-define-from-file=config/local.json`.
/// - Produkcijski parametri se ne čuvaju hardkodovani u git repozitorijumu.
class SupabaseConfig {
  SupabaseConfig._();

  // Podrazumevani javni domen i lokalni parametri
  static const String _defaultShareBaseUrl = 'https://www.domacimarket.rs';

  // Lokalni parametri (standardni lokalni Supabase dev stack)
  static const String _localUrl = 'http://127.0.0.1:54321';
  static const String _localAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
  static const String _localShareBaseUrl = 'http://localhost:3000';

  /// Trenutno okruženje prosleđeno kroz `--dart-define=APP_ENV=local|staging|prod`.
  static const String appEnv = String.fromEnvironment('APP_ENV');

  /// Da li je izabrana produkcija.
  static bool get isProd => appEnv.toLowerCase() == 'prod';

  /// Da li je aktivno lokalno okruženje.
  static bool get isLocal => appEnv.toLowerCase() == 'local';

  /// Da li je aktivno staging okruženje.
  static bool get isStaging => appEnv.toLowerCase() == 'staging';

  /// Supabase endpoint URL.
  static String get url {
    const fromEnv = String.fromEnvironment('SUPABASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (isLocal) return _localUrl;
    return '';
  }

  /// Supabase anon / public API ključ.
  static String get anonKey {
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (isLocal) return _localAnonKey;
    return '';
  }

  /// Alias za publishableKey u skladu sa novijim Supabase SDK-om.
  static String get publishableKey => anonKey;

  /// Base URL za deljenje linkova (deep links, web preview).
  static String get shareBaseUrl {
    const fromEnv = String.fromEnvironment('SHARE_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (isLocal) return _localShareBaseUrl;
    return _defaultShareBaseUrl;
  }

  /// Provera da li je konfiguracija prisutna i spremna za rad.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Proverava konfiguraciju i baca [StateError] ako parametri nedostaju.
  /// Poziva se pre [Supabase.initialize] radi fail-fast zaštite.
  static void validateConfig() {
    if (!isConfigured) {
      final message = StringBuffer()
        ..writeln('══════════════════════════════════════════════════════════════════')
        ..writeln('❌ Supabase konfiguracija nije podešena!')
        ..writeln('══════════════════════════════════════════════════════════════════')
        ..writeln('Aplikacija zahteva definisane SUPABASE_URL i SUPABASE_ANON_KEY parametre')
        ..writeln('kako bi se sprečilo slučajno prepisivanje ili oštećenje podataka.')
        ..writeln()
        ..writeln('Pokrenite aplikaciju sa jednim od sledećih načina:')
        ..writeln('  1. Za lokalni razvoj:')
        ..writeln('     flutter run --dart-define=APP_ENV=local')
        ..writeln('  2. Korišćenjem konfiguracionog fajla (preporučeno):')
        ..writeln('     flutter run --dart-define-from-file=config/local.json')
        ..writeln('     (Kopirajte config/local.json.example u config/local.json)')
        ..writeln('  3. Za staging okruženje:')
        ..writeln('     flutter run --dart-define=APP_ENV=staging --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...')
        ..writeln('  4. Za produkciju:')
        ..writeln('     flutter run --dart-define-from-file=config/prod.json')
        ..writeln('══════════════════════════════════════════════════════════════════');
      throw StateError(message.toString());
    }
  }
}
