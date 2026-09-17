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


  /// Glavna metoda za obradu podataka iz notifikacije (FCM data payload).
  /// 
  /// Koristi `go` za glavne ekrane (zamenjuje ceo stack) i `push` za detaljne
  /// ekrane gde korisnik želi da se vrati nazad (chat, detalji oglasa).
  void handleNotification(Map<String, dynamic> data) {
    LoggerService.debug('NotificationHandler: Handling data', extra: data);

    // 1. Podrška za direktno prosleđivanje rute iz Supabase/FCM-a (deep link)
    final route = data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      // Za deep linkove koristimo go jer pretpostavljamo da je ruta kompletna
      router.go(route);
      return;
    }

    // 2. Logika bazirana na tipu notifikacije (legacy/strukturno)
    final type = data['type'] as String?;
    final uid = appState.user?.id;
    final conversationId = data['conversation_id'] as String?;

    if (notificationTypeIsOrderRelated(type)) {
      // Glavni ekran - koristi go
      router.go('/orders');
    } else if (type == 'support_ticket_created') {
      // Glavni ekran - koristi go
      router.go('/admin/tickets');
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
