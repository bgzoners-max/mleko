import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/app_error.dart';
import 'package:mleko/services/core/error_handler_service.dart';

/// Unit testovi za centralizovani [ErrorHandlerService]:
/// - notifikacija listenera kroz [handleError]
/// - retry semantika [executeWithRetry] (kanonski `withRetry` je pokriven u
///   `retry_utils_test.dart`; ovde se testira dodata logika: delegacija,
///   `shouldRetry` override i centralno `handleError` po iscrpljenju pokušaja)
/// - `Result` semantika [executeWithResult] i `Result.map/getOrThrow`.
void main() {
  final service = ErrorHandlerService();
  final received = <AppError>[];

  setUp(() {
    received.clear();
    service
      ..clearStatistics()
      ..addErrorListener(received.add);
  });

  tearDown(() {
    // ErrorHandlerService je singleton — obavezno skinuti listener da ne curi
    // u druge test fajlove koji dele istu instancu.
    service.removeErrorListener(received.add);
    received.clear();
    service.clearStatistics();
  });

  group('handleError', () {
    test('notificira listenere sa AppError i čuva userMessage', () async {
      await service.handleError(
        Exception('baza pala'),
        userMessage: 'Proveri konekciju.',
        context: 'test-context',
      );

      expect(received, hasLength(1));
      expect(received.first.userMessage, 'Proveri konekciju.');
      expect(received.first.originalException, isA<Exception>());
    });

    test('propušta već postojeći AppError bez preslaganja', () async {
      final original = AppError(
        message: 'original',
        userMessage: 'korisnicka poruka',
        type: ErrorType.network,
      );

      await service.handleError(original);

      expect(received, hasLength(1));
      expect(identical(received.first, original), isTrue,
          reason: 'AppError instanca mora proći nepromenjena kroz handleError.');
    });

    test('listener koji baca ne prekida ostale listenere', () async {
      final okReceived = <AppError>[];
      // Pošto ErrorHandlerService deli singleton stanje, listeneri se skidaju
      // odmah po kraju testa kako ne bi cureli u druge testove.
      void throwingListener(AppError error) => throw Exception('listener pukao');
      service
        ..addErrorListener(throwingListener)
        ..addErrorListener(okReceived.add);
      addTearDown(() => service.removeErrorListener(throwingListener));

      await service.handleError(Exception('x'));

      expect(okReceived, hasLength(1),
          reason: 'Pali listener ne sme zaustaviti notifikaciju ostalih.');
      expect(received, hasLength(1));
    });

    test('removeErrorListener zaustavlja notifikacije', () async {
      service.removeErrorListener(received.add);
      await service.handleError(Exception('x'));
      expect(received, isEmpty);
    });
  });

  group('executeWithRetry', () {
    test('ponavlja retryable AppError (network) do uspeha', () async {
      var attempts = 0;
      final result = await service.executeWithRetry<int>(
        'retry-label',
        () async {
          attempts++;
          if (attempts < 3) {
            throw AppError(message: 'net', type: ErrorType.network);
          }
          return 7;
        },
        maxRetries: 3,
        delayBetweenRetries: const Duration(milliseconds: 1),
      );

      expect(result, 7);
      expect(attempts, 3);
    });

    test('NE ponavlja non-retryable AppError (validation)', () async {
      var attempts = 0;
      await expectLater(
        service.executeWithRetry<void>(
          'validation-label',
          () async {
            attempts++;
            throw AppError(message: 'los unos', type: ErrorType.validation);
          },
          maxRetries: 3,
          delayBetweenRetries: const Duration(milliseconds: 1),
        ),
        throwsA(isA<AppError>()),
      );
      expect(attempts, 1,
          reason: 'Validaciona greška se ne sme ponavljati.');
    });

    test('shouldRetry override ima prednost nad podrazumevanim predikatom',
        () async {
      var attempts = 0;
      await expectLater(
        service.executeWithRetry<void>(
          'override-label',
          () async {
            attempts++;
            throw AppError(message: 'net', type: ErrorType.network);
          },
          maxRetries: 3,
          delayBetweenRetries: const Duration(milliseconds: 1),
          shouldRetry: (_) => false,
        ),
        throwsA(isA<AppError>()),
      );
      expect(attempts, 1,
          reason: 'Custom shouldRetry=false mora prekinuti retry odmah.');
    });

    test('posle iscrpljenih pokušaja rethrow-a i poziva centralni handleError',
        () async {
      received.clear();
      var attempts = 0;

      await expectLater(
        service.executeWithRetry<void>(
          'exhaust-label',
          () async {
            attempts++;
            throw Exception('stalno pada');
          },
          maxRetries: 2,
          delayBetweenRetries: const Duration(milliseconds: 1),
        ),
        throwsA(isA<Exception>()),
      );

      expect(attempts, 2);
      expect(received, hasLength(1),
          reason:
              'executeWithRetry mora prijaviti konačni neuspeh kroz handleError.');
    });
  });

  group('executeWithResult', () {
    test('vraća Result.success sa podacima bez throwanja', () async {
      final result = await service.executeWithResult<String>(
        'ok-label',
        () async => 'vrednost',
      );

      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), 'vrednost');
      expect(result.error, isNull);
    });

    test('vraća Result.failure i notificira listenere', () async {
      received.clear();
      final result = await service.executeWithResult<String>(
        'fail-label',
        () async => throw Exception('palo'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, isA<AppError>());
      expect(result.getOrNull(), isNull);
      expect(received, hasLength(1),
          reason: 'executeWithResult prijavljuje neuspeh kroz handleError.');
    });
  });

  group('Result', () {
    test('map transformiše uspešnu vrednost', () {
      final result = _success;
      final mapped = result.map((v) => v * 2);
      expect(mapped.isSuccess, isTrue);
      expect(mapped.getOrNull(), 84);
    });

    test('map propušta failure bez pozivanja mapper-a', () {
      final failure = Result<int>.failure(
        AppError(message: 'x', type: ErrorType.unknown),
      );
      var mapperCalled = false;
      final mapped = failure.map((v) {
        mapperCalled = true;
        return v;
      });
      expect(mapperCalled, isFalse);
      expect(mapped.isSuccess, isFalse);
    });

    test('getOrThrow vraća vrednost ili baca AppError', () {
      final success = _success;
      expect(success.getOrThrow(), 42);

      final failure = Result<int>.failure(
        AppError(message: 'x', type: ErrorType.unknown),
      );
      expect(failure.getOrThrow, throwsA(isA<AppError>()));
    });
  });
}

// Top-level `final` u Dart-u je lenjo inicijalizovan — sigurno za deljenje.
final Result<int> _success = Result<int>.success(42);

