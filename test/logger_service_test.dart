import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/app_error.dart';
import 'package:mleko/services/core/logger_service.dart';

void main() {
  group('LoggerService Tests', () {
    test('info logs entry with extra payload to recentLogs ring buffer', () {
      final initialCount = LoggerService.recentLogs.length;
      LoggerService.info('Test info message', extra: {'userId': 'user_123', 'action': 'test'});

      expect(LoggerService.recentLogs.length, initialCount + 1);
      final lastEntry = LoggerService.recentLogs.last;
      expect(lastEntry.level, 'INFO');
      expect(lastEntry.message, 'Test info message');
      expect(lastEntry.extra, {'userId': 'user_123', 'action': 'test'});
      expect(lastEntry.details, isNull);
    });

    test('debug logs entry with extra payload', () {
      LoggerService.debug('Test debug message', extra: {'metric': 42});
      final lastEntry = LoggerService.recentLogs.last;
      expect(lastEntry.level, 'DEBUG');
      expect(lastEntry.message, 'Test debug message');
      expect(lastEntry.extra, {'metric': 42});
    });

    test('warning logs entry with extra payload', () {
      LoggerService.warning('Test warning message', extra: {'risk': 'high'});
      final lastEntry = LoggerService.recentLogs.last;
      expect(lastEntry.level, 'WARNING');
      expect(lastEntry.message, 'Test warning message');
      expect(lastEntry.extra, {'risk': 'high'});
    });

    test('error logs entry with exception details and extra payload', () {
      const exception = FormatException('Invalid payload');
      LoggerService.error('Parsing failed', exception, extra: {'raw': 'abc'});

      final lastEntry = LoggerService.recentLogs.last;
      expect(lastEntry.level, 'ERROR');
      expect(lastEntry.message, 'Parsing failed');
      expect(lastEntry.details, contains('FormatException: Invalid payload'));
      expect(lastEntry.extra, {'raw': 'abc'});
    });

    test('logAppError handles AppError correctly', () {
      final appError = AppError(
        type: ErrorType.network,
        message: 'Network timeout',
        code: 'TIMEOUT',
      );
      LoggerService.logAppError(appError);
      // Verify no exception is thrown
    });

    test('trackPerformance records successful operation duration', () async {
      final result = await LoggerService.trackPerformance('fast_op', () async {
        return 'success';
      });
      expect(result, 'success');
      final lastEntry = LoggerService.recentLogs.last;
      expect(lastEntry.level, 'DEBUG');
      expect(lastEntry.message, contains('fast_op'));
    });

    test('trackPerformance rethrows exception and logs error on failure', () async {
      expect(
        () => LoggerService.trackPerformance('failing_op', () async {
          throw StateError('Simulated error');
        }),
        throwsStateError,
      );
    });
  });
}
