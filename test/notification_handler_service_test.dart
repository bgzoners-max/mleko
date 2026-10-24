import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/services/core/notification_handler_service.dart';
import 'package:mleko/services/orders/orders_service.dart';

class _MockRouter implements GoRouter {
  String? lastGoPath;
  String? lastPushPath;

  @override
  void go(String location, {Object? extra}) {
    lastGoPath = location;
  }

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) {
    lastPushPath = location;
    return Future.value(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('NotificationHandlerService Route Whitelist (isAllowedRoute)', () {
    test('allows standard application user routes', () {
      expect(NotificationHandlerService.isAllowedRoute('/orders'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/orders/active'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/orders/archived'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/orders/order-uuid-123'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/orders?tab=active'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/chat/conv-456'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/conversations'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/classifieds'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/classifieds/my'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/classifieds/saved-searches'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/classifieds/ad/ad-789'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/notifications'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/support'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/support/ticket/tick-101'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/seller/user-1/reviews'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/buyer/user-2/reviews'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/product/prod-999'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/cart'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/favorites'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/favorite-sellers'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/settings'), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/profile'), isTrue);
    });

    test('strictly blocks malicious URLs, external schemes, and path traversals', () {
      expect(NotificationHandlerService.isAllowedRoute('https://malicious.com'), isFalse);
      expect(NotificationHandlerService.isAllowedRoute('http://evil.com/login'), isFalse);
      expect(NotificationHandlerService.isAllowedRoute('//evil.com/payload'), isFalse);
      expect(NotificationHandlerService.isAllowedRoute('javascript:alert(1)'), isFalse);
      expect(NotificationHandlerService.isAllowedRoute(''), isFalse);
      expect(NotificationHandlerService.isAllowedRoute(null), isFalse);
      expect(NotificationHandlerService.isAllowedRoute('orders'), isFalse);
      expect(NotificationHandlerService.isAllowedRoute('/orders/../admin/tickets'), isFalse);
    });

    test('strictly blocks admin routes for standard users', () {
      expect(NotificationHandlerService.isAllowedRoute('/admin/tickets', isAdmin: false), isFalse);
      expect(NotificationHandlerService.isAllowedRoute('/admin/tickets/123', isAdmin: false), isFalse);
      expect(NotificationHandlerService.isAllowedRoute('/admin/push-health', isAdmin: false), isFalse);
      expect(NotificationHandlerService.isAllowedRoute('/admin/classifieds', isAdmin: false), isFalse);
      expect(NotificationHandlerService.isAllowedRoute('/admin/arbitrary', isAdmin: false), isFalse);
    });

    test('permits whitelisted admin routes only when isAdmin is true', () {
      expect(NotificationHandlerService.isAllowedRoute('/admin/tickets', isAdmin: true), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/admin/tickets/tick-55', isAdmin: true), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/admin/push-health', isAdmin: true), isTrue);
      expect(NotificationHandlerService.isAllowedRoute('/admin/classifieds', isAdmin: true), isTrue);

      // Still rejects arbitrary unknown admin routes and external links
      expect(NotificationHandlerService.isAllowedRoute('/admin/database-dump', isAdmin: true), isFalse);
      expect(NotificationHandlerService.isAllowedRoute('https://admin-phish.com', isAdmin: true), isFalse);
    });
  });

  group('NotificationHandlerService Navigation Dispatch', () {
    late _MockRouter mockRouter;
    late AppState appState;

    setUp(() {
      mockRouter = _MockRouter();
      appState = AppState(ordersService: OrdersService());
    });

    test('whitelisted route in payload triggers router.go', () {
      final handler = NotificationHandlerService(router: mockRouter, appState: appState)
        // Whitelisted absolute route goes through router.go
        ..handleNotification({'route': '/orders/active'});
      expect(mockRouter.lastGoPath, equals('/orders/active'));

      handler.handleNotification({'route': '/chat/conversation-xyz'});
      expect(mockRouter.lastGoPath, equals('/chat/conversation-xyz'));
    });

    test('disallowed route in payload is dropped and falls back to safe type-based routing', () {
      final handler = NotificationHandlerService(router: mockRouter, appState: appState)
        // Malicious route + valid order event: dropped route, falls back to /orders
        ..handleNotification({
          'route': 'https://evil.com/steal-token',
          'type': 'new_order',
        });
      expect(mockRouter.lastGoPath, equals('/orders'));

      // Non-admin payload trying to push to admin screen: dropped route, falls back to chat
      handler.handleNotification({
        'route': '/admin/push-health',
        'type': 'new_message',
        'conversation_id': 'conv-safe-1',
      });
      expect(mockRouter.lastPushPath, equals('/chat/conv-safe-1'));
    });

    test('support_ticket_created routes to /admin/tickets only for admin, fallback /support for user', () {
      final handler = NotificationHandlerService(router: mockRouter, appState: appState)
        // Standard user
        ..handleNotification({'type': 'support_ticket_created'});
      expect(mockRouter.lastGoPath, equals('/support'));

      // Admin user
      appState.setUserForTesting(
        const UserModel(
          id: 'admin-1',
          email: 'admin@domacimarket.rs',
          displayName: 'Super Admin',
          isAdmin: true,
        ),
      );

      handler.handleNotification({'type': 'support_ticket_created'});
      expect(mockRouter.lastGoPath, equals('/admin/tickets'));
    });
  });
}
