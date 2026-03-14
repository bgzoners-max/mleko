import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../../supabase_config.dart';
import '../core/logger_service.dart';
import 'order_queue_service.dart';
import 'order_sync_service.dart';
import 'orders_service.dart';

class BackgroundSyncService {
  static const _periodicTaskUniqueName = 'mleko.periodic.order.sync';

  static Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> registerPeriodicOrderSync() async {
    if (kIsWeb) {
      return;
    }
    await Workmanager().registerPeriodicTask(
      _periodicTaskUniqueName,
      OrderSyncService.taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      initialDelay: const Duration(minutes: 5),
    );
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      WidgetsFlutterBinding.ensureInitialized();

      if (task != OrderSyncService.taskName) {
        return true;
      }

      try {
        await _ensureSupabaseInitialized();

        final syncService = OrderSyncService(
          queueService: OrderQueueService(),
          ordersService: OrdersService(),
        );
        await syncService.syncPendingOrders(
          skipConnectivityCheck: true,
          source: 'background',
        );
        return true;
      } catch (e, st) {
        LoggerService.error('Background sync task failed', e, stackTrace: st);
        return false;
      }
    });
  }

  static Future<void> _ensureSupabaseInitialized() async {
    try {
      Supabase.instance.client;
      return;
    } catch (_) {
      // Supabase is not initialized in this isolate.
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
}
