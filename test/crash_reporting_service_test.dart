import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/services/core/crash_reporting_service.dart';

class MockCrashReporter implements CrashReporter {
  @override
  String get name => 'MockReporter';

  bool initialized = false;
  final List<dynamic> recordedErrors = [];
  final List<FlutterErrorDetails> recordedFlutterErrors = [];
  String? currentUserId;
  final Map<String, Object> customKeys = {};
  final List<String> logs = [];

  @override
  Future<void> initialize({bool enableInDev = false}) async {
    initialized = true;
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    recordedErrors.add(exception);
  }

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    recordedFlutterErrors.add(details);
  }

  @override
  Future<void> setUserIdentifier(String? userId) async {
    currentUserId = userId;
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    customKeys[key] = value;
  }

  @override
  Future<void> log(String message) async {
    logs.add(message);
  }
}

class FaultyCrashReporter implements CrashReporter {
  @override
  String get name => 'FaultyReporter';

  @override
  Future<void> initialize({bool enableInDev = false}) async {
    throw Exception('Init failed');
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    throw Exception('Record error failed');
  }

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    throw Exception('Record flutter error failed');
  }

  @override
  Future<void> setUserIdentifier(String? userId) async {
    throw Exception('Set user failed');
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    throw Exception('Set key failed');
  }

  @override
  Future<void> log(String message) async {
    throw Exception('Log failed');
  }
}

void main() {
  group('CrashReportingService Tests', () {
    late MockCrashReporter mockReporter;

    setUp(() {
      CrashReportingService.clearReporters();
      mockReporter = MockCrashReporter();
      CrashReportingService.registerReporter(mockReporter);
    });

    tearDown(() {
      CrashReportingService.clearReporters();
    });

    test('initializes all registered reporters', () async {
      expect(mockReporter.initialized, isFalse);
      await CrashReportingService.initialize();
      expect(mockReporter.initialized, isTrue);
      expect(CrashReportingService.isInitialized, isTrue);
    });

    test('forwards recordError to registered reporters', () async {
      final testError = StateError('Test state error');
      await CrashReportingService.recordError(testError, StackTrace.current, reason: 'Testing');
      expect(mockReporter.recordedErrors, contains(testError));
    });

    test('forwards recordFlutterError to registered reporters', () async {
      const details = FlutterErrorDetails(exception: 'Widget failure');
      await CrashReportingService.recordFlutterError(details);
      expect(mockReporter.recordedFlutterErrors, contains(details));
    });

    test('syncs user identifier and custom keys', () async {
      await CrashReportingService.setUserIdentifier('user-1234');
      expect(mockReporter.currentUserId, equals('user-1234'));

      await CrashReportingService.setUserIdentifier(null);
      expect(mockReporter.currentUserId, isNull);

      await CrashReportingService.setCustomKey('screen', 'checkout');
      expect(mockReporter.customKeys['screen'], equals('checkout'));

      await CrashReportingService.log('Navigated to checkout');
      expect(mockReporter.logs, contains('Navigated to checkout'));
    });

    test('safely swallows reporter errors without throwing', () async {
      final faulty = FaultyCrashReporter();
      CrashReportingService.registerReporter(faulty);

      // Ni jedna od sledećih metoda ne sme baciti izuzetak
      await CrashReportingService.initialize();
      await CrashReportingService.recordError(Exception('test'), null);
      await CrashReportingService.recordFlutterError(const FlutterErrorDetails(exception: 'test'));
      await CrashReportingService.setUserIdentifier('abc');
      await CrashReportingService.setCustomKey('key', 'val');
      await CrashReportingService.log('test log');
    });
  });
}
