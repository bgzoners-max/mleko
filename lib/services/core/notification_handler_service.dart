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
  void handleNotification(Map<String, dynamic> data) {
    LoggerService.debug('NotificationHandler: Handling data', extra: data);

    // 1. Podrška za direktno prosleđivanje rute iz Supabase/FCM-a (deep link)
    final route = data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      router.push(route);
      return;
    }

    // 2. Logika bazirana na tipu notifikacije (legacy/strukturno)
    final type = data['type'] as String?;
    final uid = appState.user?.id;
    final conversationId = data['conversation_id'] as String?;

    if (notificationTypeIsOrderRelated(type)) {
      router.go('/orders');
    } else if (type == 'support_ticket_created') {
      router.go('/admin/tickets');
    } else if (type == 'new_message') {
      if (conversationId != null) {
        router.push('/chat/$conversationId');
      } else {
        router.go('/conversations');
      }
    } else if (type == 'new_review' && uid != null) {
      router.go('/seller/$uid/reviews');
    } else if (type == 'new_buyer_review' && uid != null) {
      router.go('/buyer/$uid/reviews');
    } else if (type == 'new_review' || type == 'new_buyer_review') {
      router.go('/notifications');
    } else if (type == 'admin_reply') {
      final ticketId = data['ticket_id'] as String?;
      if (ticketId != null) {
        router.go('/support/ticket/$ticketId');
      } else {
        router.go('/support');
      }
    } else if (type == 'classified_ad_moderation') {
      router.go('/classifieds/my');
    } else if (notificationTypeIsClassifiedRelated(type)) {
      final adId = data['classified_ad_id'] as String?;
      if (adId != null && adId.isNotEmpty) {
        router.push('/classifieds/ad/$adId');
      } else {
        router.go('/classifieds');
      }
    } else {
      LoggerService.info('NotificationHandler: Unknown notification type',
          extra: {'type': type});
    }
  }
}
