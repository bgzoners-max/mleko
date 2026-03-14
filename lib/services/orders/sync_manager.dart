import 'dart:async';
import 'package:flutter/foundation.dart';
import 'order_queue_service.dart';
import 'orders_service.dart';
import '../core/connectivity_service.dart';
import '../core/logger_service.dart';
import 'order_sync_service.dart';

/// Sinhronizuje pending orders kada se internet vrati
class SyncManager extends ChangeNotifier {
  final ConnectivityService _connectivity;
  final OrderSyncService _orderSyncService;

  bool _isSyncing = false;
  String? _syncError;
  int _syncedCount = 0;

  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  int get syncedCount => _syncedCount;

  SyncManager({
    required OrderQueueService queueService,
    required OrdersService ordersService,
    required ConnectivityService connectivity,
  })  : _orderSyncService = OrderSyncService(
          queueService: queueService,
          ordersService: ordersService,
        ),
        _connectivity = connectivity {
    // Sinhronizuj kada se internet vrati
    _connectivity.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (_connectivity.isOnline && !_isSyncing) {
      syncPendingOrders();
    }
  }

  /// Sinhronizuj sve pending porudžbine sa serverom
  Future<void> syncPendingOrders() async {
    if (_isSyncing || _connectivity.isOffline) {
      LoggerService.debug(
          'Sync skipped: isSyncing=$_isSyncing, isOnline=${_connectivity.isOnline}');
      return;
    }

    _isSyncing = true;
    _syncError = null;
    _syncedCount = 0;
    notifyListeners();

    try {
      _syncedCount = await _orderSyncService.syncPendingOrders(
        connectivity: _connectivity,
      );
      LoggerService.info('Foreground sync completed',
          extra: {'syncedCount': _syncedCount});
      notifyListeners();
    } catch (e, st) {
      _syncError = e.toString();
      LoggerService.error('Sync failed', e, stackTrace: st);
      notifyListeners();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
