import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/supabase_config.dart';

void main() {
  group('SupabaseConfig Environment & Safety', () {
    if (SupabaseConfig.appEnv == 'local') {
      test('when APP_ENV=local, resolves to local Supabase stack and isConfigured', () {
        expect(SupabaseConfig.isLocal, isTrue);
        expect(SupabaseConfig.isProd, isFalse);
        expect(SupabaseConfig.isStaging, isFalse);
        expect(SupabaseConfig.url, equals('http://127.0.0.1:54321'));
        expect(SupabaseConfig.anonKey, isNotEmpty);
        expect(SupabaseConfig.shareBaseUrl, equals('http://localhost:3000'));
        expect(SupabaseConfig.isConfigured, isTrue);
        expect(() => SupabaseConfig.validateConfig(), returnsNormally);
      });
    } else {
      test('in unconfigured debug/test mode, does NOT fall back to production DB', () {
        // By default in flutter test (without --dart-define), appEnv should be empty
        // and isConfigured should be false to prevent accidental writes to production.
        expect(SupabaseConfig.appEnv, isEmpty);
        expect(SupabaseConfig.isProd, isFalse);
        expect(SupabaseConfig.isLocal, isFalse);
        expect(SupabaseConfig.isStaging, isFalse);
        expect(SupabaseConfig.url, isEmpty);
        expect(SupabaseConfig.anonKey, isEmpty);
        expect(SupabaseConfig.isConfigured, isFalse);
      });

      test('validateConfig() throws StateError when unconfigured with clear instructions', () {
        expect(
          () => SupabaseConfig.validateConfig(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('Supabase konfiguracija nije podešena'),
                contains('APP_ENV=local'),
                contains('config/local.json'),
              ),
            ),
          ),
        );
      });
    }
  });
}
