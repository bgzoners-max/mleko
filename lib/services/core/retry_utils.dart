import 'dart:async';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

final math.Random _jitterRandom = math.Random();

/// Kanonska, jedina low-level retry logika u aplikaciji.
///
/// Pokreće [op] do [maxAttempts] puta sa eksponencijalnim backoff-om i jitterom
/// (sprečava „thundering herd”). Viši nivo `ErrorHandlerService.executeWithRetry`
/// delegira ovome i samo dodaje logovanje + centralno `handleError` na kraju.
///
/// Podrazumevano ne ponavlja greške koje ponavljanje neće popraviti:
/// [AuthException] (neautorizovano), [StorageException] (dozvole/nestao fajl) i
/// [PostgrestException] (validacija/RLS/business rule). Za drugačije ponašanje
/// prosledi [shouldRetry].
Future<T> withRetry<T>(
  Future<T> Function() op, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 250),
  bool Function(Object error)? shouldRetry,
}) async {
  assert(maxAttempts > 0);
  var attempt = 0;
  while (true) {
    attempt++;
    try {
      return await op();
    } catch (e) {
      final retryable = shouldRetry?.call(e) ?? defaultRetryPredicate(e);
      if (!retryable || attempt >= maxAttempts) rethrow;
      await Future<void>.delayed(backoffDelay(baseDelay, attempt));
    }
  }
}

/// Podrazumevani predikat: ponavljamo samo prolazne greške.
bool defaultRetryPredicate(Object error) {
  if (error is AuthException) return false;
  if (error is StorageException) return false;
  if (error is PostgrestException) return false;
  return true;
}

/// Eksponencijalni backoff (1x, 2x, 4x, ... max 32x) sa +[0,100)ms jittera.
Duration backoffDelay(Duration base, int attempt) {
  final cappedAttempt = attempt > 6 ? 6 : attempt;
  final multiplier = 1 << (cappedAttempt - 1); // 1, 2, 4, 8, 16, 32
  return base * multiplier +
      Duration(milliseconds: _jitterRandom.nextInt(100));
}
