import 'dart:async';
import 'dart:ui' show PlatformDispatcher, PointerDeviceKind;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as p_provider;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_providers.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'providers/app_settings_provider.dart';
import 'providers/app_state.dart';
import 'services/communication/communication_services.dart';
import 'services/core/crash_reporting_service.dart';
import 'services/core/logger_service.dart';
import 'services/core/notification_handler_service.dart';
import 'services/core/secure_local_storage.dart';
import 'widgets/common/app_error_widget.dart';
import 'providers/cart_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/location_provider.dart';
import 'providers/classifieds_provider.dart';
import 'services/auth/auth_services.dart';
import 'services/catalog/catalog_services.dart';
import 'services/orders/order_services.dart';
import 'services/social/social_services.dart';
import 'services/classifieds/classifieds_service.dart';
import 'services/classifieds/classified_reports_service.dart';
import 'widgets/global_keyboard_scroll.dart';
import 'widgets/offline_indicator.dart';
import 'supabase_config.dart';

class GlobalScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Svi skrol barovi su uklonjeni (nevidljivi)
    return child;
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
    // Uhvati prethodnu vrednost SINHRONO, pre nego što se _wasSyncing ažurira,
    // jer se frame callback (koji čita stanje) izvršava tek posle ovog poziva.
    final wasSyncing = _wasSyncing;
    _wasSyncing = manager.isSyncing;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!wasSyncing && manager.isSyncing) {
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
      } else if (wasSyncing && !manager.isSyncing) {
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

  // Graceful fallback za sve greške u renderovanju widgeta
  ErrorWidget.builder = (details) {
    CrashReportingService.recordFlutterError(details);
    return AppErrorWidget(details: details);
  };

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashReportingService.recordFlutterError(details);
    LoggerService.error(
      'FlutterError: ${details.exceptionAsString()}',
      'FlutterError: ${details.exceptionAsString()}: ${details.exception}',
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashReportingService.recordError(error, stack, fatal: true);
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
      await CrashReportingService.initialize();
    } catch (e) {
      LoggerService.warning(
        'Firebase initialization failed - push notifications and crash reporting disabled',
        extra: {'error': e.toString()},
      );
    }
  } else {
    await CrashReportingService.initialize();
  }

  await initializeDateFormatting('sr', null);

  SupabaseConfig.validateConfig();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    // Čuva sesiju (access + refresh token) u flutter_secure_storage
    // (Keystore/Keychain) umesto plaintext SharedPreferences / localStorage.
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(),
    ),
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
  final classifiedsService = ClassifiedsService();
  final classifiedReportsService = ClassifiedReportsService();
  final classifiedsProvider = ClassifiedsProvider();
  final router = createRouter(appState);

  // Sinhronizacija omiljenih, korpe, praćenja oglasa i korisničkog ID-a za monitoring sa statusom prijave.
  // Guard protiv redundantnih mrežnih poziva: AppState notificira na svaku promenu stanja
  // (unread count, loading, sync status...), pa reagujemo SAMO kada se identitet prijavljenog
  // korisnika zaista promeni (prijava/odjava/promena naloga).
  String? lastSyncedUserId;
  appState.addListener(() {
    final user = appState.user;
    final userId = (user != null && !user.isGuest) ? user.id : null;
    if (userId == lastSyncedUserId) return;
    lastSyncedUserId = userId;

    if (userId != null) {
      favoritesProvider.load(userId);
      classifiedsProvider.loadSubscriptions();
      CrashReportingService.setUserIdentifier(userId);
      cartProvider.setUser(userId);
    } else {
      favoritesProvider.clear();
      classifiedsProvider.clearSubscriptions();
      CrashReportingService.setUserIdentifier(null);
      cartProvider.clearForLogout();
    }
  });

  // Notification handling
  unawaited(NotificationHandlerService(router: router, appState: appState).initialize());

  runApp(
    AppProviders(
      appState: appState,
      appSettings: appSettings,
      cartProvider: cartProvider,
      categoriesProvider: categoriesProvider,
      favoritesProvider: favoritesProvider,
      locationProvider: locationProvider,
      classifiedsProvider: classifiedsProvider,
      ordersService: ordersService,
      productsService: productsService,
      chatService: chatService,
      reviewsService: reviewsService,
      usersService: usersService,
      classifiedsService: classifiedsService,
      classifiedReportsService: classifiedReportsService,
      child: OfflineIndicator(
        child: p_provider.Consumer<AppSettingsProvider>(
          builder: (_, settings, __) => MaterialApp.router(
            title: 'Domaći market',
            theme: buildAppTheme(compact: settings.compactMode),
            darkTheme: buildAppDarkTheme(compact: settings.compactMode),
            themeMode: settings.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('sr', 'RS'),
            ],
            locale: const Locale('sr', 'RS'),
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
