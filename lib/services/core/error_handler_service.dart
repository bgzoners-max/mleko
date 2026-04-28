import 'dart:async';
import '../../models/app_error.dart';
import 'logger_service.dart';

typedef OnErrorCallback = void Function(AppError error);
typedef OnRecoverCallback = Future<void> Function();

/// Centralizovani servis za error handling u aplikaciji
class ErrorHandlerService {
  static final _instance = ErrorHandlerService._();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._();

  final List<OnErrorCallback> _errorListeners = [];
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTimes = {};

  /// Registruj callback za sve greške
  void addErrorListener(OnErrorCallback cb) {
    _errorListeners.add(cb);
  }

  /// Ukloni error listener
  void removeErrorListener(OnErrorCallback cb) {
    _errorListeners.remove(cb);
  }

  /// Obradi grešku sa auto-logging i notifikacijom
  Future<void> handleError(
    dynamic exception, {
    StackTrace? stackTrace,
    String? userMessage,
    ErrorType? type,
    String? context,
  }) async {
    final error = AppError.from(
      exception,
      userMessage: userMessage,
      type: type,
      stackTrace: stackTrace,
    );

    // Log grešku
    LoggerService.logAppError(error);

    // Track error Count for crash detection
    _trackErrorFrequency(error);

    // Pozovi sve registrovane listeners
    for (final listener in _errorListeners) {
      try {
        listener(error);
      } catch (e) {
        LoggerService.warning('Error listener failed', extra: {'error': e});
      }
    }
  }

  /// Bezbedno izvršavanje operacije sa retry logikom
  Future<T> executeWithRetry<T>(
    String label,
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delayBetweenRetries = const Duration(seconds: 1),
    bool Function(AppError)? shouldRetry,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        attempt++;
        LoggerService.debug('Pokušaj $attempt/$maxRetries: $label');
        return await operation();
      } catch (e, st) {
        final error = AppError.from(e, stackTrace: st);

        // Proveri da li trebalo retry-ati
        if (attempt < maxRetries &&
            (shouldRetry?.call(error) ?? error.isRetryable)) {
          LoggerService.warning(
            'Retry nakon greške (attempt $attempt)',
            extra: {'error': error.message},
          );
          await Future.delayed(delayBetweenRetries * attempt);
          continue;
        }

        // Sve retry pokušaje je iscrpljivano
        await handleError(e, stackTrace: st, context: label);
        rethrow;
      }
    }
  }

  /// Bezbedno izvršavanje bez throwanja - vraća Result
  Future<Result<T>> executeWithResult<T>(
    String label,
    Future<T> Function() operation,
  ) async {
    try {
      final result = await operation();
      return Result.success(result);
    } catch (e, st) {
      final error = AppError.from(e, stackTrace: st);
      await handleError(e, stackTrace: st, context: label);
      return Result.failure(error);
    }
  }

  /// Track error frequency za crash detection
  void _trackErrorFrequency(AppError error) {
    final key = error.code ?? error.type.toString();
    final now = DateTime.now();
    final lastTime = _lastErrorTimes[key];

    // Ako je prošlo više od 10 sekundi, resetujemo brojač
    if (lastTime != null && now.difference(lastTime).inSeconds > 10) {
      _errorCounts[key] = 1;
    } else {
      _errorCounts[key] = (_errorCounts[key] ?? 0) + 1;
    }
    _lastErrorTimes[key] = now;

    final count = _errorCounts[key]!;
    if (count >= 5) {
      LoggerService.warning(
        'Česta greška: $key ($count) u poslednjих 10s',
      );
      _errorCounts[key] = 0; // Resetuj brojač kako ne bi spamovao log
    }
  }

  /// Očisti error tracking statistiku
  void clearStatistics() {
    _errorCounts.clear();
    _lastErrorTimes.clear();
  }
}

/// Result type - Alternative za Try/Catch
class Result<T> {
  final T? data;
  final AppError? error;
  final bool isSuccess;

  Result({required this.data, required this.error, required this.isSuccess});

  factory Result.success(T data) => Result(
        data: data,
        error: null,
        isSuccess: true,
      );

  factory Result.failure(AppError error) => Result(
        data: null,
        error: error,
        isSuccess: false,
      );

  /// Mapuj success vrednost
  Result<U> map<U>(U Function(T) mapper) {
    if (isSuccess) {
      return Result.success(mapper(data as T));
    }
    return Result.failure(error!);
  }

  /// Dobij vrijednost ili null ako je failure
  T? getOrNull() => data;

  /// Dobij vrijednost ili throw grešku
  T getOrThrow() {
    if (isSuccess) return data as T;
    throw error!;
  }
}
