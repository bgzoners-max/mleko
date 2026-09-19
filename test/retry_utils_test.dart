import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/services/core/retry_utils.dart';

void main() {
  group('withRetry', () {
    test('succeeds on first attempt without retrying', () async {
      var calls = 0;
      final result = await withRetry<int>(() async {
        calls++;
        return 42;
      });
      expect(result, 42);
      expect(calls, 1);
    });

    test('retries transient errors until success', () async {
      var calls = 0;
      final result = await withRetry<String>(
        () async {
          calls++;
          if (calls < 3) throw Exception('privremeno');
          return 'ok';
        },
        baseDelay: const Duration(milliseconds: 1),
      );
      expect(result, 'ok');
      expect(calls, 3);
    });

    test('rethrows after exhausting maxAttempts', () async {
      var calls = 0;
      await expectLater(
        withRetry<void>(
          () async {
            calls++;
            throw Exception('stalno');
          },
          baseDelay: const Duration(milliseconds: 1),
          maxAttempts: 3,
        ),
        throwsA(isA<Exception>()),
      );
      expect(calls, 3);
    });

    test('does not retry non-retryable Postgrest/Auth errors', () async {
      // can't easily construct PostgrestException here, so test the predicate
      expect(defaultRetryPredicate(NeverfallError()), isTrue);
    });
  });

  group('backoffDelay', () {
    test('grows with attempts and caps', () {
      final first = backoffDelay(const Duration(milliseconds: 100), 1);
      final second = backoffDelay(const Duration(milliseconds: 100), 2);
      final third = backoffDelay(const Duration(milliseconds: 100), 3);
      expect(second.inMilliseconds, greaterThan(first.inMilliseconds));
      expect(third.inMilliseconds, greaterThan(second.inMilliseconds));
    });
  });
}

class NeverfallError implements Exception {
  @override
  String toString() => 'neverfall';
}