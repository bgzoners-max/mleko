import 'dart:async';
import 'dart:ui' show PlatformDispatcher, PointerDeviceKind;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, kReleaseMode;
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:google_fonts/google_fonts.dart';
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
import 'utils/image_precache_utils.dart';
import 'widgets/global_keyboard_scroll.dart';
import 'widgets/offline_indicator.dart';
import 'supabase_config.dart';

class GlobalScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Scrollbar je vidljiv samo na desktop/web radi pristupacnosti;
    // na touch uredjajima ostaje skriven.
    final platform = Theme.of(context).platform;
    final isDesktop = platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;
    if (isDesktop || kIsWeb) {
      return Scrollbar(
        controller: details.controller,
        thumbVisibility: true,
        thickness: 8.0,
        radius: const Radius.circular(8),
        child: child,
      );
    }
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
  AppImageCache.configureMemoryLimits();

  // Preload Lucide font za garantovano renderovanje mikro ikonica na webu / CanvasKit-u pre crtanja UI-ja
  if (kIsWeb) {
    try {
      final fontLoader = FontLoader('Lucide')
        ..addFont(rootBundle.load('assets/fonts/lucide.ttf'));
      await fontLoader.load();
    } catch (e) {
      LoggerService.warning('Lucide font preload skipped or failed: $e');
    }
  }

  // U release režimu za mobilne platforme isključujemo runtime fetching sa mreže radi offline rada.
  // Na webu dozvoljavamo runtime fallback kako nedostajuća varijanta fonta nikada ne bi
  // bacila fatalni Exception u browser konzolu koji ruši Lighthouse PageSpeed reviziju.
  if (kReleaseMode && !kIsWeb) {
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  // Graceful fallback za sve greške u renderovanju widgeta
  ErrorWidget.builder = (details) {
    CrashReportingService.recordFlutterError(details);
    return AppErrorWidget(details: details);
  };

  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    CrashReportingService.recordFlutterError(details, fatal: true);
    LoggerService.error(
      'Flutter error',
      details.exception,
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

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushService.initialize();
    await CrashReportingService.initialize();
  } catch (e) {
    LoggerService.warning(
      'Firebase initialization failed - push notifications or crash reporting disabled',
      extra: {'error': e.toString()},
    );
    if (kIsWeb) {
      await CrashReportingService.initialize();
    }
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
  await appSettings.ensureLoaded();
  final cartProvider = CartProvider(productsService: productsService);
  final categoriesProvider = CategoriesProvider();
  final favoritesProvider = FavoritesProvider();
  final locationProvider = LocationProvider();
  final classifiedsService = ClassifiedsService();
  final classifiedReportsService = ClassifiedReportsService();
  final classifiedsProvider = ClassifiedsProvider();
  unawaited(classifiedsProvider.loadCategories());
  final router = createRouter(appState);

  // Sinhronizacija omiljenih, korpe, praćenja oglasa i korisničkog ID-a za monitoring sa statusom prijave.
  // Guard protiv redundantnih poziva i trkačkih uslova (race conditions) pri brzoj odjavi/prijavi.
  String? lastSyncedUserId;
  int lastSyncedAuthVersion = -1;
  Future<void> syncChain = Future.value();

  appState.addListener(() {
    final user = appState.user;
    final userId = (user != null && !user.isGuest) ? user.id : null;
    final currentAuthVersion = appState.authEventVersion;

    if (userId == lastSyncedUserId && currentAuthVersion == lastSyncedAuthVersion) return;
    lastSyncedUserId = userId;
    lastSyncedAuthVersion = currentAuthVersion;

    syncChain = syncChain.then((_) async {
      // Provera da li je ovaj auth event još uvek aktuelan pre nego što počne sinhronizacija
      if (appState.authEventVersion != currentAuthVersion) return;

      if (userId != null) {
        await CrashReportingService.setUserIdentifier(userId);
        await cartProvider.setUser(userId);
        if (appState.authEventVersion != currentAuthVersion) return;

        await Future.wait([
          favoritesProvider.load(userId),
          classifiedsProvider.loadSubscriptions(),
        ]);
      } else {
        await CrashReportingService.setUserIdentifier(null);
        await cartProvider.clearForLogout();
        favoritesProvider.clear();
        classifiedsProvider.clearSubscriptions();
      }
    }).catchError((e, st) {
      LoggerService.error('Auth state sync failed', e, stackTrace: st);
    });
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
            theme: buildAppTheme(
              compact: settings.compactMode,
              fontScale: settings.fontScale,
            ),
            darkTheme: buildAppDarkTheme(
              compact: settings.compactMode,
              fontScale: settings.fontScale,
            ),
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
