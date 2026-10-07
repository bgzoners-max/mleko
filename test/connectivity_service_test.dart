import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/services/core/connectivity_service.dart';

void main() {
  group('ConnectivityService Reachability & Authoritative Signals', () {
    test('marks offline when reachability check fails (e.g. captive portal)', () async {
      final service = ConnectivityService(
        reachabilityChecker: () async => false, // Captive portal or no internet
      );

      final isReachable = await service.checkReachability();
      expect(isReachable, isFalse);
      expect(service.isOnline, isFalse);
      expect(service.isOffline, isTrue);

      service.dispose();
    });

    test('marks online when reachability check passes', () async {
      final service = ConnectivityService(
        reachabilityChecker: () async => true,
      );

      final isReachable = await service.checkReachability();
      expect(isReachable, isTrue);
      expect(service.isOnline, isTrue);
      expect(service.isOffline, isFalse);

      service.dispose();
    });

    test('initially offline (false) by default until reachability proves connection', () {
      final service = ConnectivityService(
        reachabilityChecker: () async => true,
      );

      // Na samom startu status je false dok se ne dokaže mrežna dostupnost
      expect(service.isOnline, isFalse);
      expect(service.isOffline, isTrue);

      service.dispose();
    });

    test('reportNetworkFailure on SocketException immediately marks offline', () {
      final service = ConnectivityService(
        reachabilityChecker: () async => true,
        initialOnline: true,
      );

      expect(service.isOnline, isTrue);

      var notified = false;
      service.addListener(() => notified = true);

      service.reportNetworkFailure(const SocketException('Failed host lookup'));

      expect(service.isOnline, isFalse);
      expect(service.isOffline, isTrue);
      expect(notified, isTrue);

      // Subsequent network success marks back online
      notified = false;
      service.reportNetworkSuccess();
      expect(service.isOnline, isTrue);
      expect(notified, isTrue);

      service.dispose();
    });

    test('reportNetworkFailure ignores non-network exceptions', () {
      final service = ConnectivityService(
        reachabilityChecker: () async => true,
        initialOnline: true,
      );

      expect(service.isOnline, isTrue);

      service.reportNetworkFailure(const FormatException('Bad json format'));
      expect(service.isOnline, isTrue);

      service.dispose();
    });
  });
}
