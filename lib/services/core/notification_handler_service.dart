import 'package:go_router/go_router.dart';
import '../../providers/app_state.dart';
import '../../core/notification_types.dart';
import '../core/logger_service.dart';

import '../communication/push_service.dart';

/// Servis koji enkapsulira logiku rutiranja nakon klika na notifikaciju.
class NotificationHandlerService {
  final GoRouter router;
  final AppState appState;
  final PushService _pushService = PushService();

  NotificationHandlerService({
    required this.router,
    required this.appState,
  });

  /// Inicijalizuje push handlere i proverava početnu notifikaciju.
  Future<void> initialize() async {
    try {
      PushService.setOnNotificationTapped(handleNotification);
      
      _pushService.setForegroundHandler((_) {
        appState.incrementUnreadCount();
      });
      
      _pushService.setMessageOpenedHandler((msg) => handleNotification(msg.data));

      // Provera da li je aplikacija pokrenuta klikom na notifikaciju
      final initialMsg = await _pushService.getInitialMessage();
      if (initialMsg != null) {
        handleNotification(initialMsg.data);
      }
    } catch (e, st) {
      LoggerService.warning('NotificationHandler: Initialization failed',
          extra: {'error': e.toString(), 'stackTrace': st.toString()});
    }
  }


  /// Lista dozvoljenih regex uzoraka za rute iz push notifikacija za standardne korisnike.
  static final List<RegExp> _allowedUserRoutePatterns = [
    RegExp(r'^/orders(/(active|archived|[a-zA-Z0-9_\-]+))?$'),
    RegExp(r'^/chat/[a-zA-Z0-9_\-]+$'),
    RegExp(r'^/conversations$'),
    RegExp(r'^/classifieds(/(my|saved-searches))?$'),
    RegExp(r'^/classifieds/ad/[a-zA-Z0-9_\-]+$'),
    RegExp(r'^/notifications$'),
    RegExp(r'^/support(/ticket/[a-zA-Z0-9_\-]+)?$'),
    RegExp(r'^/(seller|buyer)/[a-zA-Z0-9_\-]+(/reviews)?$'),
    RegExp(r'^/product/[a-zA-Z0-9_\-]+$'),
    RegExp(r'^/categories(/[a-zA-Z0-9_\-]+)?$'),
    RegExp(r'^/favorites$'),
    RegExp(r'^/favorite-sellers$'),
    RegExp(r'^/settings$'),
    RegExp(r'^/profile$'),
    RegExp(r'^/cart$'),
    RegExp(r'^/sellers-map$'),
  ];

  /// Lista dozvoljenih regex uzoraka za admin rute iz push notifikacija.
  static final List<RegExp> _allowedAdminRoutePatterns = [
    RegExp(r'^/admin/tickets(/[a-zA-Z0-9_\-]+)?$'),
    RegExp(r'^/admin/push-health$'),
    RegExp(r'^/admin/classifieds$'),
  ];

  /// Proverava da li je zadata ruta bezbedna i dozvoljena za navigaciju iz push payload-a.
  static bool isAllowedRoute(String? route, {bool isAdmin = false}) {
    if (route == null || route.isEmpty) return false;

    // Odbaci eksterne šeme (http://, https://, javascript:) i protokol-relativne (//)
    final uri = Uri.tryParse(route);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !uri.path.startsWith('/') ||
        uri.path.startsWith('//')) {
      return false;
    }

    final path = uri.normalizePath().path;

    // Provera standardnih korisničkih ruta
    for (final pattern in _allowedUserRoutePatterns) {
      if (pattern.hasMatch(path)) {
        return true;
      }
    }

    // Provera admin ruta (samo ako korisnik ima admin privilegije)
    if (isAdmin) {
      for (final pattern in _allowedAdminRoutePatterns) {
        if (pattern.hasMatch(path)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Glavna metoda za obradu podataka iz notifikacije (FCM data payload).
  /// 
  /// Koristi `go` za glavne ekrane (zamenjuje ceo stack) i `push` za detaljne
  /// ekrane gde korisnik želi da se vrati nazad (chat, detalji oglasa).
  void handleNotification(Map<String, dynamic> data) {
    LoggerService.debug('NotificationHandler: Handling data', extra: data);

    final isAdmin = appState.user?.isAdmin == true;

    // 1. Podrška za direktno prosleđivanje rute iz Supabase/FCM-a (deep link) uz striktan whitelist
    final route = data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      if (isAllowedRoute(route, isAdmin: isAdmin)) {
        router.go(route);
        return;
      } else {
        LoggerService.warning(
          'NotificationHandler: Disallowed or unsafe route rejected from push payload',
          extra: {'route': route, 'isAdmin': isAdmin},
        );
        // Ne dozvoljavamo arbitrarnu rutu; nastavljamo sa obradom po tipu ako postoji
      }
    }

    // 2. Logika bazirana na tipu notifikacije (legacy/strukturno)
    final type = data['type'] as String?;
    final uid = appState.user?.id;
    final conversationId = data['conversation_id'] as String?;

    if (notificationTypeIsOrderRelated(type)) {
      // Glavni ekran - koristi go
      router.go('/orders');
    } else if (type == 'support_ticket_created') {
      if (isAdmin) {
        // Samo administratori idu na pregled tiketa
        router.go('/admin/tickets');
      } else {
        LoggerService.warning(
          'NotificationHandler: Non-admin received support_ticket_created, redirecting to /support',
        );
        router.go('/support');
      }
    } else if (type == 'new_message') {
      if (conversationId != null) {
        // Detaljni ekran (chat) - koristi push da bi korisnik mogao da se vrati
        router.push('/chat/$conversationId');
      } else {
        // Glavni ekran - koristi go
        router.go('/conversations');
      }
    } else if (type == 'new_review' && uid != null) {
      // Glavni ekran - koristi go
      router.go('/seller/$uid/reviews');
    } else if (type == 'new_buyer_review' && uid != null) {
      // Glavni ekran - koristi go
      router.go('/buyer/$uid/reviews');
    } else if (type == 'new_review' || type == 'new_buyer_review') {
      // Glavni ekran - koristi go
      router.go('/notifications');
    } else if (type == 'admin_reply') {
      final ticketId = data['ticket_id'] as String?;
      if (ticketId != null) {
        // Detaljni ekran (chat tiket) - koristi push da bi korisnik mogao da se vrati
        router.push('/support/ticket/$ticketId');
      } else {
        // Glavni ekran - koristi go
        router.go('/support');
      }
    } else if (type == 'classified_ad_moderation') {
      // Glavni ekran - koristi go
      router.go('/classifieds/my');
    } else if (notificationTypeIsClassifiedRelated(type)) {
      final adId = data['classified_ad_id'] as String?;
      if (adId != null && adId.isNotEmpty) {
        // Detaljni ekran (oglas) - koristi push da bi korisnik mogao da se vrati
        router.push('/classifieds/ad/$adId');
      } else {
        // Glavni ekran - koristi go
        router.go('/classifieds');
      }
    } else {
      LoggerService.info('NotificationHandler: Unknown notification type',
          extra: {'type': type});
    }
  }
}
