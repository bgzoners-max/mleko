import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/action_debouncer.dart';

void main() {
  group('ActionDebouncer tests', () {
    test('run debounces calls until duration passes', () async {
      final debouncer = ActionDebouncer(defaultDuration: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer
        ..run(() => callCount++)
        ..run(() => callCount++)
        ..run(() => callCount++);

      expect(callCount, equals(0));
      await Future.delayed(const Duration(milliseconds: 80));
      expect(callCount, equals(1));
      debouncer.dispose();
    });

    test('throttle executes immediately and suppresses calls within interval', () async {
      final debouncer = ActionDebouncer(defaultDuration: const Duration(milliseconds: 60));
      int callCount = 0;

      final first = debouncer.throttle(() => callCount++);
      final second = debouncer.throttle(() => callCount++);
      expect(first, isTrue);
      expect(second, isFalse);
      expect(callCount, equals(1));

      await Future.delayed(const Duration(milliseconds: 70));
      final third = debouncer.throttle(() => callCount++);
      expect(third, isTrue);
      expect(callCount, equals(2));
      debouncer.dispose();
    });

    test('runAsync prevents concurrent async execution', () async {
      final debouncer = ActionDebouncer();

      Future<int> slowTask(int val) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return val;
      }

      final f1 = debouncer.runAsync(() => slowTask(10));
      final f2 = debouncer.runAsync(() => slowTask(20));

      final res1 = await f1;
      final res2 = await f2;

      expect(res1, equals(10));
      expect(res2, isNull);
      debouncer.dispose();
    });
  });
}
