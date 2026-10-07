import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/core/web_seo.dart';
import 'package:mleko/services/core/connectivity_service.dart';
import 'package:mleko/services/orders/order_queue_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/services/orders/sync_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOrdersService extends Fake implements OrdersService {}

class _TestQueueService extends OrderQueueService {
  int getPendingCalls = 0;

  @override
  Future<List<PendingOrder>> getPendingOrders({bool onlyUnsynced = true}) async {
    getPendingCalls++;
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SyncManager Mutex & Serialization (P2)', () {
    test('concurrent syncPendingOrders calls serialize through Future chain without race condition', () async {
      final connectivity = ConnectivityService(
        reachabilityChecker: () async => true,
        initialOnline: true,
      );

      final queueService = _TestQueueService();
      final syncManager = SyncManager(
        queueService: queueService,
        ordersService: _FakeOrdersService(),
        connectivity: connectivity,
      );

      // Pokreni 3 konkurentna sync poziva u isto vreme
      final future1 = syncManager.syncPendingOrders();
      final future2 = syncManager.syncPendingOrders();
      final future3 = syncManager.syncPendingOrders();

      // Sva tri moraju uspešno da se završe bez greške ili blokade
      await Future.wait([future1, future2, future3]);

      expect(syncManager.isSyncing, isFalse);
      expect(syncManager.syncError, isNull);

      syncManager.dispose();
      connectivity.dispose();
    });

    test('syncPendingOrders skips execution when offline', () async {
      final connectivity = ConnectivityService(
        reachabilityChecker: () async => false,
        initialOnline: false,
      );

      final queueService = _TestQueueService();
      final syncManager = SyncManager(
        queueService: queueService,
        ordersService: _FakeOrdersService(),
        connectivity: connectivity,
      );

      expect(connectivity.isOffline, isTrue);

      await syncManager.syncPendingOrders();

      expect(syncManager.isSyncing, isFalse);
      expect(syncManager.syncedCount, equals(0));

      syncManager.dispose();
      connectivity.dispose();
    });
  });

  group('Web & Initial Offline Connectivity (P2)', () {
    test('isWebOnline returns a boolean status without throwing', () {
      expect(isWebOnline, isA<bool>());
    });

    test('ConnectivityService initializes with initialOnline: false', () {
      final connectivity = ConnectivityService(
        reachabilityChecker: () async => true,
      );

      expect(connectivity.isOnline, isFalse);
      expect(connectivity.isOffline, isTrue);

      connectivity.dispose();
    });
  });
}
