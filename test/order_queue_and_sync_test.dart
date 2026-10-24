import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mleko/models/app_error.dart';
import 'package:mleko/services/core/connectivity_service.dart';
import 'package:mleko/services/orders/order_queue_service.dart';
import 'package:mleko/services/orders/order_sync_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/services/orders/sync_manager.dart';
import 'package:mleko/widgets/orders/pending_orders_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PendingOrder Serialization & Retry Tracking', () {
    test('serializes and deserializes retryCount and lastError', () {
      final now = DateTime.now();
      final order = PendingOrder(
        id: 'ord-123',
        buyerId: 'buyer-abc',
        sellerId: 'seller-xyz',
        productId: 'prod-789',
        productName: 'Domaći sir',
        quantityKg: 2.0,
        unitType: 'kg',
        buyerCity: 'Beograd',
        buyerPhone: '0601234567',
        preferCall: true,
        pickupOptions: const ['seller_delivery'],
        createdAt: now,
        retryCount: 2,
        lastError: 'Sesija istekla',
        lastAttemptAt: now,
      );

      final json = order.toJson();
      expect(json['retry_count'], equals(2));
      expect(json['last_error'], equals('Sesija istekla'));
      expect(json['last_attempt_at'], isNotNull);

      final decoded = PendingOrder.fromJson(json);
      expect(decoded.id, equals('ord-123'));
      expect(decoded.retryCount, equals(2));
      expect(decoded.lastError, equals('Sesija istekla'));
      expect(decoded.isPending, isTrue);
    });

    test('copyWith updates retry fields correctly', () {
      final order = PendingOrder(
        id: 'ord-1',
        buyerId: 'b-1',
        sellerId: 's-1',
        productId: 'p-1',
        productName: 'Mleko',
        quantityKg: 1.0,
        unitType: 'l',
        buyerCity: 'Novi Sad',
        buyerPhone: '0612345678',
        preferCall: false,
        pickupOptions: const [],
        createdAt: DateTime.now(),
      );

      expect(order.retryCount, equals(0));
      expect(order.lastError, isNull);

      final updated = order.copyWith(
        retryCount: 1,
        lastError: 'Greška mreže',
      );

      expect(updated.retryCount, equals(1));
      expect(updated.lastError, equals('Greška mreže'));
    });
  });

  group('OrderQueueService Failure Recording & Listeners', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('recordOrderFailure increments retryCount and sets lastError', () async {
      final queueService = OrderQueueService();
      var listenerTriggered = 0;
      void listener() => listenerTriggered++;
      OrderQueueService.addListener(listener);

      final order = PendingOrder(
        id: 'ord-fail-1',
        buyerId: 'b-1',
        sellerId: 's-1',
        productId: 'p-1',
        productName: 'Jabuke',
        quantityKg: 5.0,
        unitType: 'kg',
        buyerCity: 'Valjevo',
        buyerPhone: '0623456789',
        preferCall: false,
        pickupOptions: const [],
        createdAt: DateTime.now(),
      );

      await queueService.addPendingOrder(order);
      expect(listenerTriggered, equals(1));

      var pending = await queueService.getPendingOrders(onlyUnsynced: true);
      expect(pending.length, equals(1));
      expect(pending.first.retryCount, equals(0));

      await queueService.recordOrderFailure('ord-fail-1',
          error: 'Neuspešna autorizacija');
      expect(listenerTriggered, equals(2));

      pending = await queueService.getPendingOrders(onlyUnsynced: true);
      expect(pending.first.retryCount, equals(1));
      expect(pending.first.lastError, equals('Neuspešna autorizacija'));
      expect(pending.first.lastAttemptAt, isNotNull);

      OrderQueueService.removeListener(listener);
    });

    test('addPendingOrder rejects duplicate IDs and markAsSynced/cleanSyncedOrders works', () async {
      final queueService = OrderQueueService();
      final now = DateTime.now();

      final o1 = PendingOrder(
        id: 'ord-dup-1',
        buyerId: 'b-1',
        sellerId: 's-1',
        productId: 'p-1',
        productName: 'Jabuke',
        quantityKg: 5.0,
        unitType: 'kg',
        buyerCity: 'Valjevo',
        buyerPhone: '0623456789',
        preferCall: false,
        pickupOptions: const [],
        createdAt: now,
      );

      final o2 = PendingOrder(
        id: 'ord-dup-2',
        buyerId: 'b-1',
        sellerId: 's-1',
        productId: 'p-2',
        productName: 'Kruške',
        quantityKg: 3.0,
        unitType: 'kg',
        buyerCity: 'Valjevo',
        buyerPhone: '0623456789',
        preferCall: false,
        pickupOptions: const [],
        createdAt: now,
      );

      await queueService.addPendingOrder(o1);
      // Adding duplicate ID
      await queueService.addPendingOrder(o1);
      expect(await queueService.getPendingCount(), 1);

      await queueService.addPendingOrder(o2);
      expect(await queueService.getPendingCount(), 2);

      // Mark o1 as synced
      await queueService.markAsSynced('ord-dup-1');
      expect(await queueService.getPendingCount(onlyUnsynced: true), 1);
      expect(await queueService.getPendingCount(onlyUnsynced: false), 2);

      // Clean synced orders -> only o2 remains
      await queueService.cleanSyncedOrders();
      expect(await queueService.getPendingCount(onlyUnsynced: false), 1);

      // Remove o2 -> queue empty
      await queueService.removePendingOrder('ord-dup-2');
      expect(await queueService.getPendingCount(onlyUnsynced: false), 0);
    });

    test('PendingOrder exponential backoff calculates expected delay and ready status', () {
      final now = DateTime.now();
      final baseOrder = PendingOrder(
        id: 'ord-backoff',
        buyerId: 'b-1',
        sellerId: 's-1',
        productId: 'p-1',
        productName: 'Mleko',
        quantityKg: 2.0,
        unitType: 'L',
        buyerCity: 'Beograd',
        buyerPhone: '0612345678',
        preferCall: false,
        pickupOptions: const [],
        createdAt: DateTime(2026, 1, 1),
      );

      // retryCount 0 -> zero backoff and ready
      expect(baseOrder.retryBackoff, equals(Duration.zero));
      expect(baseOrder.isReadyForRetry, isTrue);

      // retryCount 1 -> 2^1 * 5s = 10s
      final retry1 = baseOrder.copyWith(
        retryCount: 1,
        lastAttemptAt: now.subtract(const Duration(seconds: 5)),
      );
      expect(retry1.retryBackoff, equals(const Duration(seconds: 10)));
      expect(retry1.isReadyForRetry, isFalse);

      final retry1Ready = baseOrder.copyWith(
        retryCount: 1,
        lastAttemptAt: now.subtract(const Duration(seconds: 12)),
      );
      expect(retry1Ready.isReadyForRetry, isTrue);

      // retryCount 3 -> 2^3 * 5s = 40s
      final retry3 = baseOrder.copyWith(
        retryCount: 3,
        lastAttemptAt: now.subtract(const Duration(seconds: 25)),
      );
      expect(retry3.retryBackoff, equals(const Duration(seconds: 40)));
      expect(retry3.isReadyForRetry, isFalse);

      // retryCount 10 -> capped at 3600s (1h)
      final retry10 = baseOrder.copyWith(retryCount: 10);
      expect(retry10.retryBackoff, equals(const Duration(hours: 1)));
    });

    test('OrderQueueService enforces maxQueueLength of 50', () async {
      final queueService = OrderQueueService();
      SharedPreferences.setMockInitialValues({});

      for (var i = 0; i < OrderQueueService.maxQueueLength; i++) {
        await queueService.addPendingOrder(PendingOrder(
          id: 'ord-cap-$i',
          buyerId: 'b-1',
          sellerId: 's-1',
          productId: 'p-$i',
          productName: 'Proizvod $i',
          quantityKg: 1.0,
          unitType: 'kg',
          buyerCity: 'Novi Sad',
          buyerPhone: '0611111111',
          preferCall: false,
          pickupOptions: const [],
          createdAt: DateTime.now(),
        ));
      }

      expect(await queueService.getPendingCount(onlyUnsynced: true),
          equals(OrderQueueService.maxQueueLength));

      // Attempting to add 51st item should throw AppError
      expect(
        () => queueService.addPendingOrder(PendingOrder(
          id: 'ord-cap-overflow',
          buyerId: 'b-1',
          sellerId: 's-1',
          productId: 'p-overflow',
          productName: 'Overflow proizvod',
          quantityKg: 1.0,
          unitType: 'kg',
          buyerCity: 'Novi Sad',
          buyerPhone: '0611111111',
          preferCall: false,
          pickupOptions: const [],
          createdAt: DateTime.now(),
        )),
        throwsA(isA<AppError>()),
      );

      // Once synced items are marked and cleaned, new items can be added again
      await queueService.markAsSynced('ord-cap-0');
      await queueService.cleanSyncedOrders();

      expect(await queueService.getPendingCount(onlyUnsynced: true), equals(49));

      await queueService.addPendingOrder(PendingOrder(
        id: 'ord-cap-after-clean',
        buyerId: 'b-1',
        sellerId: 's-1',
        productId: 'p-after-clean',
        productName: 'Dozvoljen proizvod',
        quantityKg: 1.0,
        unitType: 'kg',
        buyerCity: 'Novi Sad',
        buyerPhone: '0611111111',
        preferCall: false,
        pickupOptions: const [],
        createdAt: DateTime.now(),
      ));

      expect(await queueService.getPendingCount(onlyUnsynced: true), equals(50));
    });
  });

  group('SyncManager and PendingOrdersBanner UI', () {
    testWidgets('PendingOrdersBanner renders pending orders and error details',
        (tester) async {
      final order = PendingOrder(
        id: 'ord-ui-1',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        productId: 'p-1',
        productName: 'Kajmak',
        quantityKg: 0.5,
        unitType: 'kg',
        buyerCity: 'Čačak',
        buyerPhone: '0634567890',
        preferCall: true,
        pickupOptions: const [],
        createdAt: DateTime.now(),
        retryCount: 3,
        lastError: 'Sesija nije pronađena u pozadini',
      );

      final syncManager = _TestSyncManager([order]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingOrdersBanner(syncManager: syncManager),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 porudžbina čeka slanje na server'), findsOneWidget);
      expect(find.textContaining('Kajmak (0.5 kg)'), findsOneWidget);
      expect(find.textContaining('Pokušano 3 puta'), findsOneWidget);
      expect(find.text('Pošalji sada'), findsOneWidget);
    });

    testWidgets('PendingOrdersBanner renders nothing when queue is empty',
        (tester) async {
      final syncManager = _TestSyncManager([]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingOrdersBanner(syncManager: syncManager),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PendingOrdersBanner), findsOneWidget);
      expect(find.text('Pošalji sada'), findsNothing);
    });
  });

  group('OrderSyncService offline skip & empty queue tests', () {
    test('syncPendingOrders skips sync when connectivity is offline', () async {
      final queueService = OrderQueueService();
      final syncService = OrderSyncService(
        queueService: queueService,
        ordersService: OrdersService(),
      );

      final connectivity = ConnectivityService(reachabilityChecker: () async => false)
        ..reportNetworkFailure(const SocketException('No route to host'));
      expect(connectivity.isOffline, isTrue);

      final result = await syncService.syncPendingOrders(
        connectivity: connectivity,
        skipConnectivityCheck: false,
      );

      expect(result, equals(0));
    });

    test('syncPendingOrders returns 0 immediately when queue is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final queueService = OrderQueueService();
      final syncService = OrderSyncService(
        queueService: queueService,
        ordersService: OrdersService(),
      );

      final connectivity = ConnectivityService(reachabilityChecker: () async => true)
        ..reportNetworkSuccess();
      expect(connectivity.isOnline, isTrue);

      final result = await syncService.syncPendingOrders(
        connectivity: connectivity,
        skipConnectivityCheck: false,
      );

      expect(result, equals(0));
    });
  });
}

class _TestSyncManager extends ChangeNotifier implements SyncManager {
  final List<PendingOrder> _orders;
  final bool _syncing;

  _TestSyncManager(this._orders, {bool syncing = false}) : _syncing = syncing;

  @override
  List<PendingOrder> get pendingOrders => _orders;

  @override
  int get pendingCount => _orders.length;

  @override
  bool get hasPendingOrders => _orders.isNotEmpty;

  @override
  bool get isSyncing => _syncing;

  @override
  String? get syncError => null;

  @override
  int get syncedCount => 0;

  @override
  Future<void> refreshPendingOrders() async {}

  @override
  Future<void> syncPendingOrders() async {}
}
