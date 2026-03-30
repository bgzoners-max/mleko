import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as p_provider;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/notification_types.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'providers/app_settings_provider.dart';
import 'providers/app_state.dart';
import 'services/communication/communication_services.dart';
import 'services/core/logger_service.dart';
import 'providers/cart_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/location_provider.dart';
import 'services/orders/sync_manager.dart';
import 'widgets/offline_indicator.dart';
import 'supabase_config.dart';

class _SyncFeedbackListener extends StatefulWidget {
  final Widget child;
  const _SyncFeedbackListener({required this.child});

  @override
  State<_SyncFeedbackListener> createState() => _SyncFeedbackListenerState();
}

class _SyncFeedbackListenerState extends State<_SyncFeedbackListener> {
  SyncManager? _syncManager;
  bool _wasSyncing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final manager = context.read<AppState>().syncManager;
    if (manager != _syncManager) {
      _syncManager?.removeListener(_onSyncChanged);
      _syncManager = manager;
      _syncManager!.addListener(_onSyncChanged);
    }
  }

  void _onSyncChanged() {
    final manager = _syncManager;
    if (manager == null) return;
    if (_wasSyncing && !manager.isSyncing && manager.syncedCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              manager.syncedCount == 1
                  ? 'Porudžbina je sinhronizovana.'
                  : '${manager.syncedCount} porudžbine sinhronizovane.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }
    _wasSyncing = manager.isSyncing;
  }

  @override
  void dispose() {
    _syncManager?.removeListener(_onSyncChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LoggerService.error(
      'FlutterError: ${details.exceptionAsString()}',
      'FlutterError: ${details.exceptionAsString()}: ${details.exception}',
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    LoggerService.error(
      'Uncaught async error',
      error,
      stackTrace: stack,
    );
    return true;
  };

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await PushService.initialize();
    } catch (e) {
      LoggerService.warning(
        'Firebase initialization failed - push notifications disabled',
        extra: {'error': e.toString()},
      );
    }
  }

  await initializeDateFormatting('sr', null);

  await SupabaseConfig.load();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final appState = AppState();
  final appSettings = AppSettingsProvider();
  final cartProvider = CartProvider();
  final categoriesProvider = CategoriesProvider();
  final favoritesProvider = FavoritesProvider();
  final locationProvider = LocationProvider();
  final router = createRouter(appState);

  try {
    final pushService = PushService();
    void navigateFromNotification(Map<String, dynamic> data) {
      final type = data['type'] as String?;
      final uid = appState.user?.id;
      if (notificationTypeIsOrderRelated(type)) {
        router.go('/orders');
      } else if (type == 'new_message') {
        router.go('/conversations');
      } else if (type == 'new_review' && uid != null) {
        router.go('/seller/$uid/reviews');
      } else if (type == 'new_buyer_review' && uid != null) {
        router.go('/buyer/$uid/reviews');
      } else if (type == 'new_review' || type == 'new_buyer_review') {
        router.go('/notifications');
      }
    }

    PushService.setOnNotificationTapped(navigateFromNotification);
    pushService.setForegroundHandler((_) {
      appState.incrementUnreadCount();
    });
    pushService
        .setMessageOpenedHandler((msg) => navigateFromNotification(msg.data));
    Future.microtask(() async {
      try {
        final initialMsg = await pushService.getInitialMessage();
        if (initialMsg != null) {
          navigateFromNotification(initialMsg.data);
        }
      } catch (e) {
        LoggerService.debug('Initial notification check failed',
            extra: {'error': e.toString()});
      }
    });
  } catch (e) {
    LoggerService.warning('Push notification setup failed',
        extra: {'error': e.toString()});
  }

  runApp(
    ProviderScope(
      child: p_provider.MultiProvider(
        providers: [
          p_provider.ChangeNotifierProvider<AppState>.value(value: appState),
          p_provider.ChangeNotifierProvider<AppSettingsProvider>.value(
              value: appSettings),
          p_provider.ChangeNotifierProvider<CartProvider>.value(
              value: cartProvider),
          p_provider.ChangeNotifierProvider<CategoriesProvider>.value(
              value: categoriesProvider),
          p_provider.ChangeNotifierProvider<FavoritesProvider>.value(
              value: favoritesProvider),
          p_provider.ChangeNotifierProvider<LocationProvider>.value(
              value: locationProvider),
        ],
        child: OfflineIndicator(
          child: p_provider.Consumer<AppSettingsProvider>(
            builder: (_, settings, __) => MaterialApp.router(
              title: 'Naše Selo',
              theme: buildAppTheme(compact: settings.compactMode),
              darkTheme: buildAppDarkTheme(compact: settings.compactMode),
              themeMode: settings.themeMode,
              routerConfig: router,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(settings.fontScale),
                  ),
                  child: _SyncFeedbackListener(
                    child: child ??
                        const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
