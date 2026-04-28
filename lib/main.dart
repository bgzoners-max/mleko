import 'dart:ui' show PlatformDispatcher, PointerDeviceKind;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as p_provider;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_providers.dart';
import 'core/notification_types.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'providers/app_settings_provider.dart';
import 'providers/app_state.dart';
import 'services/communication/communication_services.dart';
import 'services/core/logger_service.dart';
import 'services/core/notification_handler_service.dart';
import 'providers/cart_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/location_provider.dart';
import 'services/auth/auth_services.dart';
import 'services/catalog/catalog_services.dart';
import 'services/orders/order_services.dart';
import 'services/social/social_services.dart';
import 'widgets/global_keyboard_scroll.dart';
import 'widgets/offline_indicator.dart';
import 'supabase_config.dart';

class GlobalScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Na desktopu i webu uvek želimo vidljiv scrollbar
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      child: child,
    );
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_wasSyncing && manager.isSyncing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Slanje offline porudžbina...'),
              ],
            ),
            duration: Duration(minutes: 2),
          ),
        );
      } else if (_wasSyncing && !manager.isSyncing) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (manager.syncedCount > 0) {
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
        }
      }
    });
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

  try {
    await BackgroundSyncService.initialize();
    await BackgroundSyncService.registerPeriodicOrderSync();
  } catch (e, st) {
    LoggerService.warning(
      'Background order sync setup failed',
      extra: {'error': e.toString(), 'stackTrace': st.toString()},
    );
  }

  final ordersService = OrdersService();
  final productsService = ProductsService();
  final chatService = ChatService();
  final reviewsService = ReviewsService();
  final usersService = UsersService();

  final appState = AppState(ordersService: ordersService);
  final appSettings = AppSettingsProvider();
  final cartProvider = CartProvider(productsService: productsService);
  final categoriesProvider = CategoriesProvider();
  final favoritesProvider = FavoritesProvider();
  final locationProvider = LocationProvider();
  final router = createRouter(appState);

  // Notification handling
  NotificationHandlerService(router: router, appState: appState).initialize();

  runApp(
    AppProviders(
      appState: appState,
      appSettings: appSettings,
      cartProvider: cartProvider,
      categoriesProvider: categoriesProvider,
      favoritesProvider: favoritesProvider,
      locationProvider: locationProvider,
      ordersService: ordersService,
      productsService: productsService,
      chatService: chatService,
      reviewsService: reviewsService,
      usersService: usersService,
      child: OfflineIndicator(
        child: p_provider.Consumer<AppSettingsProvider>(
          builder: (_, settings, __) => MaterialApp.router(
            title: 'Domaći market',
            theme: buildAppTheme(compact: settings.compactMode),
            darkTheme: buildAppDarkTheme(compact: settings.compactMode),
            themeMode: settings.themeMode,
            routerConfig: router,
            scrollBehavior: GlobalScrollBehavior(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.fontScale),
                ),
                child: GlobalKeyboardScroll(
                  child: _SyncFeedbackListener(
                    child: child ??
                        const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
