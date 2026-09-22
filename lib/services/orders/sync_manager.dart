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
  final OrderQueueService _queueService;

  bool _isSyncing = false;
  String? _syncError;
  int _syncedCount = 0;
  List<PendingOrder> _pendingOrders = [];

  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  int get syncedCount => _syncedCount;
  List<PendingOrder> get pendingOrders => List.unmodifiable(_pendingOrders);
  int get pendingCount => _pendingOrders.length;
  bool get hasPendingOrders => _pendingOrders.isNotEmpty;

  SyncManager({
    required OrderQueueService queueService,
    required OrdersService ordersService,
    required ConnectivityService connectivity,
  })  : _queueService = queueService,
        _orderSyncService = OrderSyncService(
          queueService: queueService,
          ordersService: ordersService,
        ),
        _connectivity = connectivity {
    // Sinhronizuj kada se internet vrati
    _connectivity.addListener(_onConnectivityChanged);
    OrderQueueService.addListener(_onQueueChanged);
    refreshPendingOrders();
  }

  void _onConnectivityChanged() {
    if (_connectivity.isOnline && !_isSyncing) {
      syncPendingOrders();
    }
  }

  void _onQueueChanged() {
    refreshPendingOrders();
  }

  /// Osvežava lokalnu listu pending porudžbina
  Future<void> refreshPendingOrders() async {
    try {
      _pendingOrders =
          await _queueService.getPendingOrders(onlyUnsynced: true);
      notifyListeners();
    } catch (e) {
      LoggerService.warning('Failed to refresh pending orders list: $e');
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
      if (_syncedCount > 0) {
        _connectivity.reportNetworkSuccess();
      }
      LoggerService.info('Foreground sync completed',
          extra: {'syncedCount': _syncedCount});
    } catch (e, st) {
      _syncError = e.toString();
      _connectivity.reportNetworkFailure(e);
      LoggerService.error('Sync failed', e, stackTrace: st);
    } finally {
      await refreshPendingOrders();
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    OrderQueueService.removeListener(_onQueueChanged);
    super.dispose();
  }
}
