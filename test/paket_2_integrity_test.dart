import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mleko/models/order_item_model.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/favorites_provider.dart';
import 'package:mleko/services/services.dart';
import 'package:mleko/utils/number_input_utils.dart';
import 'package:mleko/widgets/offline_indicator.dart';

class _FakeAppState extends ChangeNotifier implements AppState {
  bool _offline = true;

  @override
  bool get isOffline => _offline;

  set offline(bool v) {
    _offline = v;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingFavoritesService extends Fake implements FavoritesService {
  @override
  Future<List<String>> getFavoriteProductIds(String userId) async => ['p1'];

  @override
  Future<void> removeFavorite(String userId, String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    throw Exception('401 Unauthorized after logout');
  }
}

class _FakeOrdersService extends Fake implements OrdersService {}

class _StatefulProbe extends StatefulWidget {
  const _StatefulProbe();

  @override
  State<_StatefulProbe> createState() => _StatefulProbeState();
}

class _StatefulProbeState extends State<_StatefulProbe> {
  static int initCount = 0;

  @override
  void initState() {
    super.initState();
    initCount++;
  }

  @override
  Widget build(BuildContext context) => const Text('probe-alive');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Paket 2 — Parsing, Pricing, Stock & Model Integrity', () {
    test('parseQuantityL/G/Ml handle explicit units and large liter stocks accurately', () {
      expect(ProductFormattingUtils.parseQuantityL('500'), 500.0);
      expect(ProductFormattingUtils.parseQuantityL('100 L'), 100.0);
      expect(ProductFormattingUtils.parseQuantityL('750 ml'), 0.75);
      expect(ProductFormattingUtils.parseQuantityG('0.5 g'), closeTo(0.0005, 1e-9));
      expect(ProductFormattingUtils.parseQuantityMl('0.5 ml'), closeTo(0.0005, 1e-9));
      expect(ProductFormattingUtils.parseQuantityG('30'), closeTo(0.03, 1e-9));
      expect(ProductFormattingUtils.parseQuantityMl('330'), closeTo(0.33, 1e-9));
    });

    test('NumberInputUtils.parseDecimal does not turn 0.500 or 1000.500 into thousands', () {
      expect(NumberInputUtils.parseDecimal('0.500'), 0.5);
      expect(NumberInputUtils.parseDecimal('0.250'), 0.25);
      expect(NumberInputUtils.parseDecimal('1000.500'), 1000.5);
      expect(NumberInputUtils.parseDecimal('1.500'), 1500.0);
      expect(NumberInputUtils.parseDecimal('185.000'), 185000.0);
    });

    test('OrderItemModel preserves DB total_price for sub-unit items', () {
      final teaItem = OrderItemModel.fromJson({
        'product_id': 'p-tea',
        'product_name': 'Biljni čaj 30g',
        'quantity_kg': 0.03,
        'unit_type': 'kg',
        'unit_price': 300.0,
        'total_price': 300.0,
      });

      expect(teaItem.totalPrice, 300.0);
      expect(teaItem.toJson()['total_price'], 300.0);
    });

    test('ProductModel preserves sub-unit pricing with variants, basePricePerKg, and orderCount', () {
      final base = ProductModel(
        id: 'p-jam',
        sellerId: 's1',
        category: 'Slatko',
        name: 'Domaće slatko',
        pricePerKg: 500,
        minOrderKg: 0.33,
        orderStep: 0.33,
        availableKg: 10,
        unitType: ProductModel.unitL,
        description: '',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Beograd',
        createdAt: DateTime(2026, 1, 1),
        orderCount: 42,
        variants: const [
          ProductVariant(id: 'jagoda', label: 'Jagoda', price: 500, group: 'Ukus'),
          ProductVariant(id: 'malina', label: 'Malina', price: 550, group: 'Ukus'),
        ],
      );

      final selected = base.withSelectedVariant(base.variants[1]);
      expect(selected.isSubUnitProduct, isTrue);
      expect(selected.pricePerKg, 550);
      expect(selected.totalPriceForQuantity(0.33), 550);
      expect(selected.totalPriceForQuantity(0.66), 1100);
      expect(selected.toDbMap()['price_per_kg'], 500);
      expect(selected.toJson()['order_count'], 42);

      // Sub-unit stock: 10 tegli po 0.33L = 3.3L max
      expect(selected.exceedsAvailableStock(0.33), isFalse);
      expect(selected.exceedsAvailableStock(3.30), isFalse);
      expect(selected.exceedsAvailableStock(3.63), isTrue);

      final cleared = selected.withSelectedVariant(null);
      expect(cleared.pricePerKg, 500);
      expect(cleared.name, 'Domaće slatko');
    });
  });

  group('Paket 2 — OfflineIndicator, SyncManager & FavoritesProvider Isolation', () {
    testWidgets('OfflineIndicator does not remount child when offline state toggles',
        (tester) async {
      _StatefulProbeState.initCount = 0;
      final appState = _FakeAppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: OfflineIndicator(child: _StatefulProbe()),
          ),
        ),
      );
      expect(_StatefulProbeState.initCount, 1);
      expect(find.textContaining('Nemaš internet'), findsOneWidget);

      appState.offline = false;
      await tester.pump();
      expect(_StatefulProbeState.initCount, 1);
      expect(find.textContaining('Nemaš internet'), findsNothing);

      appState.offline = true;
      await tester.pump();
      expect(_StatefulProbeState.initCount, 1);
      expect(find.textContaining('Nemaš internet'), findsOneWidget);
    });

    test('FavoritesProvider toggle rollback does not leak after clear() on logout', () async {
      final provider = FavoritesProvider(service: _FailingFavoritesService());
      await provider.load('user-a');
      expect(provider.isFavorite('p1'), isTrue);

      final toggleFuture = provider.toggle('user-a', 'p1');
      provider.clear(); // simulira logout dok je removeFavorite u toku
      await toggleFuture;

      expect(provider.isFavorite('p1'), isFalse);
      expect(provider.count, 0);
      provider.dispose();
    });

    test('SyncManager isolates pending orders by active user and clears on logout', () async {
      final queue = OrderQueueService();
      await queue.addPendingOrder(
        PendingOrder(
          id: 'pending_user_a_1',
          buyerId: 'user-a',
          sellerId: 'seller-1',
          productId: 'prod-1',
          productName: 'Rakija',
          quantityKg: 1,
          unitType: 'L',
          buyerCity: 'Beograd',
          buyerPhone: '060111222',
          preferCall: false,
          pickupOptions: const [],
          createdAt: DateTime(2026, 11, 19),
        ),
      );

      final connectivity = ConnectivityService(initialOnline: false);
      final manager = SyncManager(
        queueService: queue,
        ordersService: _FakeOrdersService(),
        connectivity: connectivity,
      );

      await manager.setActiveUser('user-a');
      expect(manager.pendingOrders.length, 1);
      expect(manager.pendingOrders.first.buyerId, 'user-a');

      await manager.setActiveUser(null);
      expect(manager.pendingOrders, isEmpty);

      await manager.setActiveUser('user-b');
      expect(manager.pendingOrders, isEmpty);

      manager.dispose();
      connectivity.dispose();
    });
  });
}
