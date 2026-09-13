import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/refetch_throttle.dart';

void main() {
  group('RefetchThrottle', () {
    test('first acquire is allowed immediately', () {
      final throttle =
          RefetchThrottle(minInterval: const Duration(seconds: 5));
      expect(throttle.tryAcquire(), isTrue);
    });

    test('immediate second acquire is denied within the window', () {
      final throttle =
          RefetchThrottle(minInterval: const Duration(minutes: 1));
      expect(throttle.tryAcquire(), isTrue);
      expect(throttle.tryAcquire(), isFalse);
    });

    test('remainingWait is zero before any acquire', () {
      final throttle =
          RefetchThrottle(minInterval: const Duration(seconds: 5));
      expect(throttle.remainingWait, Duration.zero);
    });

    test('remainingWait counts down and acquire succeeds after interval',
        () async {
      final throttle =
          RefetchThrottle(minInterval: const Duration(milliseconds: 30));
      expect(throttle.tryAcquire(), isTrue);
      expect(throttle.remainingWait > Duration.zero, isTrue);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(throttle.remainingWait, Duration.zero);
      expect(throttle.tryAcquire(), isTrue);
    });

    test('reset allows immediate acquire again', () {
      final throttle =
          RefetchThrottle(minInterval: const Duration(minutes: 1));
      throttle.tryAcquire();
      expect(throttle.tryAcquire(), isFalse);
      throttle.reset();
      expect(throttle.tryAcquire(), isTrue);
    });
  });
}