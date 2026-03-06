// ============================================================================
// ERROR HANDLING BEST PRACTICES - NAŠE SELO
// ============================================================================
//
// Ovaj fajl sadrži primere kako koristiti novi error handling sistem.
//
// ============================================================================

// ============================================================================
// 1. BASIC ERROR LOGGING
// ============================================================================

import 'package:flutter/material.dart';
import 'services/logger_service.dart';
import 'services/error_handler_service.dart';
import 'models/app_error.dart';
import 'widgets/error_dialog.dart';

class BasicErrorExample {
  // LOŠE - stari način
  void oldWay() {
    try {
      // neka operacija
    } catch (_) {
      // šta se dešava ovde? Ko zna!
    }
  }

  // DOBRO - novi način
  void newWay() {
    try {
      // neka operacija
    } catch (e, st) {
      LoggerService.error('Operacija nije uspela', e, stackTrace: st);
    }
  }
}

// ============================================================================
// 2. USER MESSAGES
// ============================================================================

class UserMessageExample {
  Future<void> loadProducts() async {
    try {
      // učitaj proizvode
    } catch (e, st) {
      final error = AppError.from(
        e,
        stackTrace: st,
        userMessage: 'Nije moguće učitati proizvode. Proveri internet konekciju.',
      );
      await ErrorHandlerService().handleError(e, stackTrace: st);
    }
  }
}

// ============================================================================
// 3. RETRY LOGIC SA AUTOMATIC RETRIES
// ============================================================================

class RetryExample {
  final errorHandler = ErrorHandlerService();

  // Automatski pokušaj 3 puta sa 1s delay-om između pokušaja
  Future<List<dynamic>> loadProductsWithRetry() async {
    return errorHandler.executeWithRetry(
      'Load products',
      () => Future.delayed(
        Duration(seconds: 1),
        () => [], // zameni sa actual API call
      ),
      maxRetries: 3,
      delayBetweenRetries: const Duration(seconds: 1),
      // Samo retry-aj network greške
      shouldRetry: (error) => error.isNetworkError,
    );
  }
}

// ============================================================================
// 4. RETRY BUTTON U UI-JU
// ============================================================================

class RetryButtonExample extends StatefulWidget {
  @override
  State<RetryButtonExample> createState() => _RetryButtonExampleState();
}

class _RetryButtonExampleState extends State<RetryButtonExample> {
  Future? _loadingFuture;

  Future<void> _loadData() async {
    setState(() => _loadingFuture = _fetchData());
  }

  Future<void> _fetchData() async {
    try {
      // API call
      throw Exception('Network error');
    } catch (e, st) {
      final error = AppError.from(e, stackTrace: st);
      if (mounted) {
        // Prikaži error dialog sa retry dugmetom
        await ErrorDialog.show(
          context,
          error: error,
          onRetry: _loadData, // Automat retry
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Column(
            children: [
              Text('Greška: ${snapshot.error}'),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Pokušaj ponovno'),
              ),
            ],
          );
        }
        return const Text('Uspešno učitano!');
      },
    );
  }
}

// ============================================================================
// 5. ERROR SNACKBAR
// ============================================================================

class ErrorSnackbarExample {
  void showErrorMessage(BuildContext context) {
    try {
      // neka operacija
      throw Exception('Nešto je pošlo naopako');
    } catch (e, st) {
      final error = AppError.from(e, stackTrace: st);

      // Prikaži error kao snackbar
      ErrorSnackBar.show(
        context,
        error: error,
        onRetry: () => showErrorMessage(context),
      );
    }
  }
}

// ============================================================================
// 6. RESULT<T> - ALTERNATIVE APPROACH
// ============================================================================

class ResultExample {
  final errorHandler = ErrorHandlerService();

  // Koristi Result<T> umesto try-catch
  Future<Result<String>> fetchUserName(String userId) {
    return errorHandler.executeWithResult(
      'Fetch user name',
      () async {
        // neka operacija
        return 'Ivan';
      },
    );
  }

  // Koristi rezultat
  Future<void> example() async {
    final result = await fetchUserName('123');

    if (result.isSuccess) {
      print('Korisnik: ${result.data}');
    } else {
      print('Greška: ${result.error?.getUserMessage()}');
    }
  }
}

// ============================================================================
// 7. GLOBAL ERROR LISTENER (notifications, analytics, itd)
// ============================================================================

class GlobalErrorListenerExample {
  static void setupGlobalErrorHandling() {
    final errorHandler = ErrorHandlerService();

    errorHandler.addErrorListener((error) {
      // Log u analytics
      // _analytics.logEvent(
      //   name: 'app_error',
      //   parameters: {
      //     'type': error.type.toString(),
      //     'code': error.code,
      //     'message': error.message,
      //   },
      // );

      // Send to crash reporting (Firebase Crashlytics)
      // FirebaseCrashlytics.instance.recordError(
      //   error.originalException,
      //   error.stackTrace,
      // );

      LoggerService.info('Global error listener notified: ${error.type}');
    });
  }
}

// ============================================================================
// 8. ERROR TYPES - KAKO DETEKTOVATI VRSTU GREŠKE
// ============================================================================

class ErrorTypeExample {
  Future<void> handleDifferentErrors(dynamic exception) async {
    final error = AppError.from(exception);

    // NETWORK GREŠKE
    if (error.isNetworkError) {
      // Prikaži offline ekran
      // Queuj operacije za kasnije
    }

    // TIMEOUT GREŠKE
    if (error.isTimeout) {
      // Ponudi retry sa nižim timeout-om
    }

    // AUTHORIZATION GREŠKE
    if (error.isUnauthorized) {
      // Zatraži login ponovno
      // Navigiraj na login ekran
    }

    // OSTALE GREŠKE
    switch (error.type) {
      case ErrorType.forbidden:
        // Nemaš dozvolu
        break;
      case ErrorType.notFound:
        // 404 - nešto nije pronađeno
        break;
      case ErrorType.validation:
        // Validacijska greška - prikaži formular sa error-ima
        break;
      case ErrorType.conflict:
        // Konflikt - stavka već postoji
        break;
      default:
        // Unknown error
        break;
    }
  }
}

// ============================================================================
// 9. PERFORMANCE TRACKING
// ============================================================================

class PerformanceTrackingExample {
  Future<void> trackSlowOperations() async {
    // Ovo će log-ovati ako operacija traje duže od 500ms
    await LoggerService.trackPerformance(
      'Load heavy data',
      () => Future.delayed(Duration(seconds: 2)),
    );
  }
}

// ============================================================================
// 10. BEST PRACTICES SUMMARY
// ============================================================================

/*
✅ DO - DOBRI PRIMERI:
1. Uvek zaloguj error sa detaljima: LoggerService.error('msg', e, stackTrace: st)
2. Koristi AppError.from() za normalizaciju greške
3. Prosledi custom userMessage ako je drugačija od default-a
4. Koristi ErrorDialog.show() za korisničke dijaloge
5. Koristi ErrorSnackBar.show() za male notifikacije
6. Koristi executeWithRetry() za retry logiku
7. Koristi executeWithResult() umesto try-catch ako je moguće
8. Registruj global error listener za analytics

❌ DON'T - LOŠI PRIMERI:
1. Nikad catch (_) {} - UVEK prosledi exception i stackTrace
2. Nikad debugPrint() umesto LoggerService.error()
3. Nikad prosledi technical error kao userMessage
4. Nikad ne ignoriši greške bez barem logging-a
5. Nikad ne rify-aj non-retryable greške (authorization, validation)

⚠️  GREŠKE KOJE NE TREBAJU RETRY:
- Unauthorized (401)
- Forbidden (403)
- Not Found (404)
- Bad Request (400)
- Validation errors

✓ GREŠKE KOJE TREBAJU RETRY:
- Network errors
- Timeouts
- Server errors (5xx)
- Temporary service unavailable (503)
*/
