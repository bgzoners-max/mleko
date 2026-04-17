/// Strukturovana reprezentacija greške u aplikaciji
class AppError {
  final String message;
  final String? userMessage;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final ErrorType type;

  AppError({
    required this.message,
    this.userMessage,
    this.code,
    this.originalException,
    this.stackTrace,
    ErrorType? type,
  })  : type = type ?? ErrorType.unknown,
        timestamp = DateTime.now();

  static AppError from(
    dynamic exception, {
    String? userMessage,
    ErrorType? type,
    StackTrace? stackTrace,
  }) {
    if (exception is AppError) return exception;

    final message = exception.toString();
    final code = _extractErrorCode(exception);
    final errorType = type ?? _detectErrorType(exception);

    return AppError(
      message: message,
      userMessage: userMessage,
      code: code,
      originalException: exception,
      stackTrace: stackTrace,
      type: errorType,
    );
  }

  static String? _extractErrorCode(dynamic exception) {
    final msg = exception.toString();
    if (msg.contains('PGRST') || msg.contains('23505')) {
      final match = RegExp(r'PGRST(\d+)').firstMatch(msg);
      return match?.group(0);
    }
    return null;
  }

  static ErrorType _detectErrorType(dynamic exception) {
    final msg = exception.toString().toLowerCase();

    if (msg.contains('network') || msg.contains('socket')) {
      return ErrorType.network;
    }
    if (msg.contains('timeout')) {
      return ErrorType.timeout;
    }
    if (msg.contains('unauthorized') || msg.contains('401')) {
      return ErrorType.unauthorized;
    }
    if (msg.contains('forbidden') || msg.contains('403')) {
      return ErrorType.forbidden;
    }
    if (msg.contains('not found') || msg.contains('404')) {
      return ErrorType.notFound;
    }
    if (msg.contains('validation') || msg.contains('bad request')) {
      return ErrorType.validation;
    }
    if (msg.contains('duplicate') ||
        msg.contains('constraint') ||
        msg.contains('23505')) {
      return ErrorType.conflict;
    }

    return ErrorType.unknown;
  }

  /// Korisničku poruku - ako nema custom, vraća default
  String getUserMessage() {
    if (userMessage != null) return userMessage!;

    return switch (type) {
      ErrorType.network =>
        'Nema interneta. Proveri konekciju i pokušaj ponovno.',
      ErrorType.timeout => 'Zahtev je trajao predugo. Pokušaj ponovno.',
      ErrorType.unauthorized => 'Sesija je istekla. Molimo prijavi se ponovo.',
      ErrorType.forbidden => 'Nemaš dozvolu za ovu akciju.',
      ErrorType.notFound => 'Traženi sadržaj nije pronađen.',
      ErrorType.validation => 'Nepravilni unos. Proveri podatke.',
      ErrorType.conflict => 'Ova stavka već postoji.',
      _ => 'Došlo je do greške. Pokušaj ponovno.'
    };
  }

  bool get isNetworkError => type == ErrorType.network;
  bool get isTimeout => type == ErrorType.timeout;
  bool get isUnauthorized => type == ErrorType.unauthorized;
  bool get isRetryable => isNetworkError || isTimeout;

  @override
  String toString() => 'AppError($type): $message';
}

enum ErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  unknown,
}
