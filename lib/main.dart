import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/app_settings_provider.dart';
import 'providers/app_state.dart';
import 'services/push_service.dart';
import 'services/core/logger_service.dart';
import 'providers/cart_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/location_provider.dart';
import 'widgets/offline_indicator.dart';
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bolje logovanje na uređaju (adb logcat / DevTools) kad nešto pukne pre UI-a.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      debugPrintStack(stackTrace: details.stack);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught async error: $error');
      debugPrintStack(stackTrace: stack);
    }
    return true;
  };

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      await PushService.initialize();
    } catch (e) {
      // Firebase nije konfigurisan – push notifikacije neće raditi
      LoggerService.warning(
        'Firebase initialization failed - push notifications disabled',
        extra: {'error': e.toString()},
      );
    }
  }

  await initializeDateFormatting('sr', null);

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  final url = supabaseUrl.isNotEmpty ? supabaseUrl : SupabaseConfig.url;
  final anonKey =
      supabaseAnonKey.isNotEmpty ? supabaseAnonKey : SupabaseConfig.anonKey;

  await Supabase.initialize(url: url, anonKey: anonKey);

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
      if (type == 'new_order' || type == 'order_status') {
        router.go('/orders');
      } else if (type == 'new_message') {
        router.go('/conversations');
      }
    }

    PushService.setOnNotificationTapped(navigateFromNotification);
    pushService.setForegroundHandler((_) {});
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
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<AppSettingsProvider>.value(value: appSettings),
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
        ChangeNotifierProvider<CategoriesProvider>.value(
            value: categoriesProvider),
        ChangeNotifierProvider<FavoritesProvider>.value(
            value: favoritesProvider),
        ChangeNotifierProvider<LocationProvider>.value(
            value: locationProvider),
      ],
      child: OfflineIndicator(
        child: Consumer<AppSettingsProvider>(
          builder: (_, settings, __) => MaterialApp.router(
            title: 'Naše Selo',
            theme: appTheme,
            darkTheme: appDarkTheme,
            themeMode: settings.themeMode,
            routerConfig: router,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.fontScale),
                ),
                // GoRouter ponekad prosleđuje `null` child tokom prvog frejma / refresh-a.
                // `SizedBox.shrink()` daje potpuno prazan ekran (često pogrešno shvaćen kao “beli ekran”).
                child: child ??
                    const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
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
