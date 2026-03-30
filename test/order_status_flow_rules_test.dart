import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/order_status_flow_rules.dart';

void main() {
  group('Order status transitions', () {
    test('allows only forward transitions', () {
      expect(
        OrderStatusFlowRules.isAllowedTransition(
          oldStatus: 'sent',
          newStatus: 'accepted',
        ),
        isTrue,
      );
      expect(
        OrderStatusFlowRules.isAllowedTransition(
          oldStatus: 'accepted',
          newStatus: 'shipped',
        ),
        isTrue,
      );
      expect(
        OrderStatusFlowRules.isAllowedTransition(
          oldStatus: 'shipped',
          newStatus: 'delivered',
        ),
        isTrue,
      );
      expect(
        OrderStatusFlowRules.isAllowedTransition(
          oldStatus: 'delivered',
          newStatus: 'arhivirano',
        ),
        isTrue,
      );
    });

    test('rejects backward and invalid transitions', () {
      expect(
        OrderStatusFlowRules.isAllowedTransition(
          oldStatus: 'accepted',
          newStatus: 'sent',
        ),
        isFalse,
      );
      expect(
        OrderStatusFlowRules.isAllowedTransition(
          oldStatus: 'sent',
          newStatus: 'delivered',
        ),
        isFalse,
      );
      expect(
        OrderStatusFlowRules.isAllowedTransition(
          oldStatus: 'arhivirano',
          newStatus: 'sent',
        ),
        isFalse,
      );
    });
  });

  group('Notifications', () {
    test('maps status to recipient and copy', () {
      final accepted =
          OrderStatusFlowRules.notificationForNewStatus('accepted');
      final delivered =
          OrderStatusFlowRules.notificationForNewStatus('delivered');

      expect(accepted, isNotNull);
      expect(accepted!.recipientRole, 'buyer');
      expect(accepted.title, 'Porudžbina prihvaćena');

      expect(delivered, isNotNull);
      expect(delivered!.recipientRole, 'seller');
      expect(delivered.title, 'Kupac potvrdio prijem');

      expect(
        OrderStatusFlowRules.notificationForNewStatus('arhivirano'),
        isNull,
      );
    });
  });

  group('Manual archive and actor role', () {
    test('buyer can manually archive only terminal statuses', () {
      expect(OrderStatusFlowRules.canBuyerManuallyArchive('delivered'), isTrue);
      expect(OrderStatusFlowRules.canBuyerManuallyArchive('rejected'), isTrue);
      expect(
        OrderStatusFlowRules.canBuyerManuallyArchive('cancelled_by_seller'),
        isTrue,
      );
      expect(OrderStatusFlowRules.canBuyerManuallyArchive('sent'), isFalse);
      expect(
        OrderStatusFlowRules.canBuyerManuallyArchive('accepted'),
        isFalse,
      );
      expect(OrderStatusFlowRules.canBuyerManuallyArchive('shipped'), isFalse);
    });

    test('seller can manually archive same terminal statuses as buyer', () {
      expect(OrderStatusFlowRules.canSellerManuallyArchive('delivered'), isTrue);
      expect(OrderStatusFlowRules.canSellerManuallyArchive('rejected'), isTrue);
      expect(
        OrderStatusFlowRules.canSellerManuallyArchive('cancelled_by_seller'),
        isTrue,
      );
      expect(OrderStatusFlowRules.canSellerManuallyArchive('sent'), isFalse);
      expect(OrderStatusFlowRules.canSellerManuallyArchive('accepted'), isFalse);
    });

    test('classifies who changed status', () {
      expect(
        OrderStatusFlowRules.actorRoleForStatusChange(
          actorUserId: 'u-buyer',
          buyerId: 'u-buyer',
          sellerId: 'u-seller',
        ),
        'buyer',
      );
      expect(
        OrderStatusFlowRules.actorRoleForStatusChange(
          actorUserId: 'u-seller',
          buyerId: 'u-buyer',
          sellerId: 'u-seller',
        ),
        'seller',
      );
      expect(
        OrderStatusFlowRules.actorRoleForStatusChange(
          actorUserId: null,
          buyerId: 'u-buyer',
          sellerId: 'u-seller',
        ),
        'system',
      );
    });
  });
}
