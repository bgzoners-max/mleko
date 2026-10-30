import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../../supabase_config.dart';
import '../core/logger_service.dart';
import '../core/secure_local_storage.dart';
import 'order_queue_service.dart';
import 'order_sync_service.dart';
import 'orders_service.dart';

class BackgroundSyncService {
  static const _periodicTaskUniqueName = 'mleko.periodic.order.sync';

  static bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> initialize() async {
    if (!_isSupportedPlatform) {
      return;
    }
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> registerPeriodicOrderSync() async {
    if (!_isSupportedPlatform) {
      return;
    }
    await Workmanager().registerPeriodicTask(
      _periodicTaskUniqueName,
      OrderSyncService.taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      initialDelay: const Duration(minutes: 5),
    );
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      // U background isolate-u obezbeđujemo WidgetsFlutterBinding
      // kako bi svi MethodChannel dodaci (shared_preferences, flutter_secure_storage)
      // imali garantovanu platformsku komunikaciju.
      WidgetsFlutterBinding.ensureInitialized();

      if (task != OrderSyncService.taskName) {
        return true;
      }

      try {
        await _ensureSupabaseInitialized();

        final queueService = OrderQueueService();
        final pendingBefore =
            await queueService.getPendingOrders(onlyUnsynced: true);
        if (pendingBefore.isEmpty) {
          LoggerService.debug('Background sync: no pending orders');
          return true;
        }

        final syncService = OrderSyncService(
          queueService: queueService,
          ordersService: OrdersService(),
        );
        final syncedCount = await syncService.syncPendingOrders(
          skipConnectivityCheck: true,
          source: 'background',
        );

        // Ako je postojala porudžbina za slanje, ali nijedna nije uspešno sinhronizovana,
        // vraćamo false kako bi Workmanager prepoznao neuspeh i aktivirao retry politiku.
        final remainingPending =
            await queueService.getPendingOrders(onlyUnsynced: true);
        if (remainingPending.isNotEmpty && syncedCount == 0) {
          LoggerService.warning(
            'Background sync: 0 orders synced out of ${pendingBefore.length} pending. Requesting retry from Workmanager.',
          );
          return false;
        }

        return true;
      } catch (e, st) {
        LoggerService.error('Background sync task failed', e, stackTrace: st);
        return false;
      }
    });
  }

  static Future<void> _ensureSupabaseInitialized() async {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession?.isExpired == true) {
        try {
          await client.auth.refreshSession();
        } catch (e) {
          LoggerService.warning('Failed to refresh session in background isolate', extra: {'error': e.toString()});
        }
      }
      return;
    } catch (_) {
      // Supabase is not initialized in this isolate.
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(),
      ),
    );

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession?.isExpired == true) {
        await client.auth.refreshSession();
      }
    } catch (e) {
      LoggerService.warning('Failed to refresh session in background sync',
          extra: {'error': e.toString()});
    }
  }
}
