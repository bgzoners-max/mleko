import 'package:supabase_flutter/supabase_flutter.dart';

/// Token registracija/cleanup u `user_push_tokens`.
///
/// Izdvojeno iz `PushService` kao korak 1 split-a: sadrži isključivo
/// Supabase upite (upsert/delete). Firebase `getToken` i lifecycle
/// (generation guard, refresh listener) ostaju u `PushService`.
class PushTokenRepository {
  PushTokenRepository({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  Future<void> removeOtherUsersForInstallation(
    String installationId,
    String userId,
  ) async {
    await _client
        .from('user_push_tokens')
        .delete()
        .eq('installation_id', installationId)
        .neq('user_id', userId);
  }

  Future<void> upsertToken({
    required String userId,
    required String installationId,
    required String token,
    required String platform,
  }) async {
    await _client.from('user_push_tokens').upsert(
      {
        'user_id': userId,
        'installation_id': installationId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,installation_id',
    );
  }

  Future<void> deleteUserInstallationTokens({
    required String userId,
    required String installationId,
  }) async {
    await _client
        .from('user_push_tokens')
        .delete()
        .eq('user_id', userId)
        .eq('installation_id', installationId);
  }
}
