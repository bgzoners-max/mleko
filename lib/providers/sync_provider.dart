import 'package:flutter/foundation.dart';
import '../services/core/connectivity_service.dart';
import '../services/orders/order_queue_service.dart';
import '../services/orders/orders_service.dart';
import '../services/orders/sync_manager.dart';

/// Izdvojeni provider za offline status, sinhronizaciju i red čekanja porudžbina.
class SyncProvider extends ChangeNotifier {
  final ConnectivityService _connectivity;
  final OrderQueueService _orderQueue;
  final OrdersService _ordersService;
  late final SyncManager _syncManager;
  late final VoidCallback _connectivityListener;

  bool get isOnline => _connectivity.isOnline;
  bool get isOffline => _connectivity.isOffline;
  ConnectivityService get connectivity => _connectivity;
  OrderQueueService get orderQueue => _orderQueue;
  SyncManager get syncManager => _syncManager;

  SyncProvider({
    required OrdersService ordersService,
    ConnectivityService? connectivityService,
    OrderQueueService? orderQueueService,
    SyncManager? syncManager,
  })  : _ordersService = ordersService,
        _connectivity = connectivityService ?? ConnectivityService(),
        _orderQueue = orderQueueService ?? OrderQueueService() {
    _syncManager = syncManager ??
        SyncManager(
          queueService: _orderQueue,
          ordersService: _ordersService,
          connectivity: _connectivity,
        );

    _connectivityListener = () => notifyListeners();
    _connectivity.addListener(_connectivityListener);
  }

  /// Ponovo pokreće sinhronizaciju — prisilno ponovo proverava mrežnu dostupnost
  /// i osvežava listu pending porudžbina. Korisno nakon greške u mrežnom sloju
  /// ili kada se želi prisilno ponovo proučiti online/offline stanje.
  ///
  /// Ne poziva `dispose()` na pod-uslugama jer one nisu idempotentne i ne mogu
  /// se ponovo instancirati (polja su `final` / `late final`).
  Future<void> reload() async {
    await _connectivity.checkReachability();
    await _syncManager.refreshPendingOrders();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivity.removeListener(_connectivityListener);
    _connectivity.dispose();
    _syncManager.dispose();
    super.dispose();
  }
}
