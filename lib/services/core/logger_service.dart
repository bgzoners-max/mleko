import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../models/app_error.dart';

/// Centralizovani logger servis za sve log poruke.
/// Čuva poslednjih [maxLoggedEntries] logova u memoriji za dijagnostiku.
class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? details;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.details,
  });
}

class LoggerService {
  static const _prefix = '[MLEKO]';
  static const _maxLoggedEntries = 500;

  // Instanciran sa singleton paternom
  static final _instance = LoggerService._();
  factory LoggerService() => _instance;
  LoggerService._();

  static final Queue<LogEntry> _logEntries = Queue<LogEntry>();
  static List<LogEntry> get recentLogs => List.unmodifiable(_logEntries);

  static void _addEntry(String level, String message, {String? details}) {
    if (_logEntries.length >= _maxLoggedEntries) {
      _logEntries.removeFirst();
    }
    _logEntries.add(LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      details: details,
    ));
  }

  /// Log info poruke
  static void info(String message, {Map<String, dynamic>? extra}) {
    _addEntry('INFO', message);
    if (kDebugMode) {
      final extraStr = extra != null ? ' | Extra: $extra' : '';
      debugPrint('$_prefix [INFO] $message$extraStr');
    }
  }

  /// Log debug poruke
  static void debug(String message, {Map<String, dynamic>? extra}) {
    _addEntry('DEBUG', message);
    if (kDebugMode) {
      final extraStr = extra != null ? ' | Extra: $extra' : '';
      debugPrint('$_prefix [DEBUG] $message$extraStr');
    }
  }

  /// Log warning poruke
  static void warning(String message, {Map<String, dynamic>? extra}) {
    _addEntry('WARNING', message);
    final extraStr = extra != null ? ' | Extra: $extra' : '';
    debugPrint('$_prefix [WARNING] $message$extraStr');
  }

  /// Log greške sa stack trace
  static void error(
    String message,
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _addEntry('ERROR', message, details: exception.toString());
    final extraStr = extra != null ? ' | Extra: $extra' : '';

    if (kDebugMode) {
      debugPrint('$_prefix [ERROR] $message$extraStr');
      debugPrint('$_prefix Exception: $exception');
      if (stackTrace != null) {
        debugPrint('$_prefix StackTrace:\n$stackTrace');
      }
    }
  }

  /// Log AppError sa svim detaljima
  static void logAppError(AppError error) {
    final message = 'Type: ${error.type}, Code: ${error.code ?? "N/A"}';
    if (kDebugMode) {
      debugPrint('$_prefix [APP_ERROR] ${error.message}');
      debugPrint('$_prefix User message: ${error.getUserMessage()}');
      debugPrint('$_prefix $message');
      if (error.stackTrace != null) {
        debugPrint('$_prefix StackTrace:\n${error.stackTrace}');
      }
    }
  }

  /// Log performanse - koristi za tracking spore operacije
  static Future<T> trackPerformance<T>(
    String label,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;
      if (ms > 500) {
        warning('Spora operacija "$label": ${ms}ms');
      } else {
        debug('Operacija "$label": ${ms}ms');
      }
      return result;
    } catch (e) {
      stopwatch.stop();
      error(
          'Operacija "$label" neuspešna nakon ${stopwatch.elapsedMilliseconds}ms',
          e);
      rethrow;
    }
  }
}

