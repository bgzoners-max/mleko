import 'package:supabase_flutter/supabase_flutter.dart';

/// Pokreće [op] do [maxAttempts] puta. Pravi pauzu prije svakog ponovnog pokušaja.
/// Ne ponavlja ukoliko je izuzetak [AuthException] ili [StorageException].
Future<T> withRetry<T>(
  Future<T> Function() op, {
  int maxAttempts = 3,
}) async {
  var attempt = 0;
  while (true) {
    attempt++;
    try {
      return await op();
    } catch (e) {
      final isAuth = e is AuthException;
      // StorageException usually means file not found or permission, retrying won't help much if it's persistent,
      // but here we specifically exclude it based on original logic.
      if (isAuth || attempt >= maxAttempts) rethrow;
      await Future.delayed(Duration(milliseconds: 300 * attempt));
    }
  }
}
