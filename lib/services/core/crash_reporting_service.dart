import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';

/// Interfejs za modularne provajdere za praćenje grešaka (npr. Crashlytics, Sentry, Mock za testove).
abstract class CrashReporter {
  String get name;
  Future<void> initialize({bool enableInDev = false});
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  });
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  });
  Future<void> setUserIdentifier(String? userId);
  Future<void> setCustomKey(String key, Object value);
  Future<void> log(String message);
}

/// Firebase Crashlytics implementacija reportera za Android i iOS.
class FirebaseCrashlyticsReporter implements CrashReporter {
  @override
  String get name => 'FirebaseCrashlytics';

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  @override
  Future<void> initialize({bool enableInDev = false}) async {
    if (kIsWeb) {
      _isAvailable = false;
      return;
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        final crashlytics = FirebaseCrashlytics.instance;
        final isEnabled = kReleaseMode || enableInDev;
        await crashlytics.setCrashlyticsCollectionEnabled(isEnabled);
        _isAvailable = true;
      } else {
        _isAvailable = false;
      }
    } catch (_) {
      _isAvailable = false;
    }
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    if (!_isAvailable) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        information: information,
        fatal: fatal,
      );
    } catch (_) {
      // Ignorišemo greške samog reportera kako ne bismo izazvali kaskadni pad
    }
  }

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    if (!_isAvailable) return;
    try {
      if (fatal) {
        await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else {
        await FirebaseCrashlytics.instance.recordFlutterError(details);
      }
    } catch (_) {
      // Tihi fallback
    }
  }

  @override
  Future<void> setUserIdentifier(String? userId) async {
    if (!_isAvailable) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
    } catch (e) {
      LoggerService.warning('FirebaseCrashlytics setUserIdentifier failed', extra: {'error': e.toString()});
    }
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    if (!_isAvailable) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      LoggerService.warning('FirebaseCrashlytics setCustomKey failed', extra: {'error': e.toString()});
    }
  }

  @override
  Future<void> log(String message) async {
    if (!_isAvailable) return;
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      LoggerService.warning('FirebaseCrashlytics log failed', extra: {'error': e.toString()});
    }
  }
}

/// Centralizovani servis za praćenje rušenja i neuhvaćenih grešaka.
///
/// Podržava višestruke aktivne reportere (Firebase Crashlytics, Sentry, in-memory za testove).
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  static final List<CrashReporter> _reporters = [
    FirebaseCrashlyticsReporter(),
  ];

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Registracija prilagođenog reportera (korisno za testove ili Sentry integraciju).
  static void registerReporter(CrashReporter reporter) {
    _reporters.add(reporter);
  }

  /// Čišćenje reportera (korisno za resetovanje tokom testiranja).
  static void clearReporters() {
    _reporters.clear();
  }

  /// Inicijalizacija svih registrovanih reportera.
  static Future<void> initialize({bool enableInDev = false}) async {
    for (final reporter in _reporters) {
      try {
        await reporter.initialize(enableInDev: enableInDev);
      } catch (_) {
        // Ignorišemo greške inicijalizacije pojedinačnih reportera
      }
    }
    _isInitialized = true;
  }

  /// Beleženje proizvoljnog izuzetka sa opcionalnim stack trace-om.
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    for (final reporter in _reporters) {
      try {
        await reporter.recordError(
          exception,
          stack,
          reason: reason,
          information: information,
          fatal: fatal,
        );
      } catch (e) {
        LoggerService.warning('CrashReportingService recordError failed', extra: {'error': e.toString()});
      }
    }
  }

  /// Beleženje grešaka unutar Flutter widget i rendering stabla.
  static Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    for (final reporter in _reporters) {
      try {
        await reporter.recordFlutterError(details, fatal: fatal);
      } catch (e) {
        LoggerService.warning('CrashReportingService recordFlutterError failed', extra: {'error': e.toString()});
      }
    }
  }

  /// Povezivanje korisnika sa izveštajima o greškama.
  static Future<void> setUserIdentifier(String? userId) async {
    for (final reporter in _reporters) {
      try {
        await reporter.setUserIdentifier(userId);
      } catch (e) {
        LoggerService.warning('CrashReportingService setUserIdentifier failed', extra: {'error': e.toString()});
      }
    }
  }

  /// Dodavanje metapodataka (npr. 'current_route', 'cart_items_count').
  static Future<void> setCustomKey(String key, Object value) async {
    for (final reporter in _reporters) {
      try {
        await reporter.setCustomKey(key, value);
      } catch (e) {
        LoggerService.warning('CrashReportingService setCustomKey failed', extra: {'error': e.toString()});
      }
    }
  }

  /// Dodavanje 'breadcrumb' poruke koja se prilaže uz izveštaj o padu.
  static Future<void> log(String message) async {
    for (final reporter in _reporters) {
      try {
        await reporter.log(message);
      } catch (e) {
        LoggerService.warning('CrashReportingService log failed', extra: {'error': e.toString()});
      }
    }
  }
}
