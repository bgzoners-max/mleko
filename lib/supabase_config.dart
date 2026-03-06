/// Supabase konfiguracija za Storage (slike proizvoda).
/// Kreiraj projekat na https://supabase.com
/// Dashboard → Settings → API → Project URL i anon public key
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://wvqtujpurhzraptorcvl.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2cXR1anB1cmh6cmFwdG9yY3ZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwODEyNDEsImV4cCI6MjA4NzY1NzI0MX0.UcZtf4geUoMJXCk3Ma87481XDQ_2plQvgWZKXxLA8ns';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Osnova URL-a za deljenje proizvoda (npr. https://mleko.rs). Prazno = koristi trenutni origin (web).
  static const String shareBaseUrl = '';
}
