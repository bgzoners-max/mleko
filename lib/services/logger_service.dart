import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Usluga za centralizovano logovanje grešaka i događaja.
class LoggerService {
  /// Loguje grešku sa opcionim stack trace-om i metapodacima.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    if (kDebugMode) {
      print('--- [ERROR] $message ---');
      if (error != null) print('Error: $error');
      if (metadata != null) print('Metadata: $metadata');
      if (stackTrace != null) print('StackTrace:\n$stackTrace');
      print('-----------------------');
    }

    _sendToRemote(message, error, stackTrace, metadata);
  }

  /// Šalje grešku na udaljeni server putem Supabase Edge funkcije
  Future<void> _sendToRemote(String message, Object? error,
      StackTrace? stackTrace, Map<String, dynamic>? metadata) async {
    try {
      // Opcija: Spreči slanje logova dok si u lokalnom razvoju
      // if (kDebugMode) return;

      await Supabase.instance.client.functions.invoke(
        'remote-log',
        body: {
          'level': 'ERROR',
          'message': message,
          'error': error?.toString(),
          'stackTrace': stackTrace?.toString(),
          'metadata': metadata,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Greška pri slanju udaljenog loga: $e');
    }
  }

  /// Loguje informativnu poruku (npr. uspeh bitne operacije).
  void info(String message, [Map<String, dynamic>? metadata]) {
    if (kDebugMode) {
      print('[INFO] $message ${metadata ?? ''}');
    }
  }

  /// Loguje upozorenje.
  void warning(String message, [Object? error]) {
    if (kDebugMode) {
      print('[WARNING] $message ${error ?? ''}');
    }
  }
}
