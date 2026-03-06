import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/order_queue_service.dart';
import '../services/orders_service.dart';
import '../services/connectivity_service.dart';
import '../services/logger_service.dart';

/// Sinhronizuje pending orders kada se internet vrati
class SyncManager extends ChangeNotifier {
  final OrderQueueService _queueService;
  final OrdersService _ordersService;
  final ConnectivityService _connectivity;

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
  })  : _queueService = queueService,
        _ordersService = ordersService,
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
      final pendingOrders =
          await _queueService.getPendingOrders(onlyUnsynced: true);
      if (pendingOrders.isEmpty) {
        LoggerService.info('No pending orders to sync');
        return;
      }

      LoggerService.info('Starting sync',
          extra: {'pendingCount': pendingOrders.length});

      for (final order in pendingOrders) {
        try {
          // Pokušaj da pošalješ order na server
          await _sendOrderToServer(order);

          // Ako je uspelo, označi kao sinhronizovano
          await _queueService.markAsSynced(order.id);
          _syncedCount++;
          notifyListeners();

          LoggerService.info('Synced order', extra: {'orderId': order.id});
        } catch (e, st) {
          LoggerService.error('Failed to sync order ${order.id}', e,
              stackTrace: st);
          // Nastavi sa sledećom porudžbinom, ne prekopaj sve
        }
      }

      // Cleanup sinhronizovanih porudžbina
      await _queueService.cleanSyncedOrders();
      LoggerService.info('Sync completed',
          extra: {'syncedCount': _syncedCount});
    } catch (e, st) {
      _syncError = e.toString();
      LoggerService.error('Sync failed', e, stackTrace: st);
      notifyListeners();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _sendOrderToServer(PendingOrder order) async {
    // TODO: Implementiraj actual server send sa OrdersService
    // Za sada, simuliraj sa delay
    await Future.delayed(const Duration(milliseconds: 500));

    // U budućnosti:
    // await _ordersService.createOrder(
    //   buyerId: order.buyerId,
    //   sellerId: order.sellerId,
    //   ...
    // );
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
