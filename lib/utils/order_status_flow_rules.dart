class OrderStatusNotificationTemplate {
  final String recipientRole;
  final String title;
  final String body;

  const OrderStatusNotificationTemplate({
    required this.recipientRole,
    required this.title,
    required this.body,
  });
}

class OrderStatusFlowRules {
  const OrderStatusFlowRules._();

  static bool isAllowedTransition({
    required String oldStatus,
    required String newStatus,
  }) {
    if (oldStatus == newStatus) {
      return true;
    }

    switch (oldStatus) {
      case 'sent':
        return newStatus == 'accepted' || newStatus == 'rejected';
      case 'accepted':
        return newStatus == 'shipped' || newStatus == 'cancelled_by_seller';
      case 'shipped':
        return newStatus == 'delivered' || newStatus == 'cancelled_by_seller';
      case 'rejected':
      case 'cancelled_by_seller':
      case 'delivered':
        return newStatus == 'arhivirano';
      case 'arhivirano':
        return false;
      default:
        return false;
    }
  }

  static OrderStatusNotificationTemplate? notificationForNewStatus(
      String newStatus) {
    switch (newStatus) {
      case 'accepted':
        return const OrderStatusNotificationTemplate(
          recipientRole: 'buyer',
          title: 'Porudžbina prihvaćena',
          body: 'Prodavac je prihvatio vašu porudžbinu.',
        );
      case 'shipped':
        return const OrderStatusNotificationTemplate(
          recipientRole: 'buyer',
          title: 'Porudžbina poslata',
          body: 'Prodavac je označio porudžbinu kao poslatu.',
        );
      case 'rejected':
        return const OrderStatusNotificationTemplate(
          recipientRole: 'buyer',
          title: 'Porudžbina odbijena',
          body: 'Prodavac je odbio vašu porudžbinu.',
        );
      case 'cancelled_by_seller':
        return const OrderStatusNotificationTemplate(
          recipientRole: 'buyer',
          title: 'Porudžbina otkazana',
          body: 'Prodavac je otkazao porudžbinu.',
        );
      case 'delivered':
        return const OrderStatusNotificationTemplate(
          recipientRole: 'seller',
          title: 'Kupac potvrdio prijem',
          body: 'Kupac je potvrdio da je primio porudžbinu.',
        );
      default:
        return null;
    }
  }

  /// Završene porudžbine koje kupac ili prodavac sme ručno da prebaci u arhivu.
  static bool _canPartyManuallyArchive(String status) {
    return status == 'delivered' ||
        status == 'rejected' ||
        status == 'cancelled_by_seller';
  }

  static bool canBuyerManuallyArchive(String status) =>
      _canPartyManuallyArchive(status);

  static bool canSellerManuallyArchive(String status) =>
      _canPartyManuallyArchive(status);

  static String actorRoleForStatusChange({
    required String? actorUserId,
    required String buyerId,
    required String sellerId,
  }) {
    if (actorUserId != null && actorUserId == buyerId) {
      return 'buyer';
    }
    if (actorUserId != null && actorUserId == sellerId) {
      return 'seller';
    }
    return 'system';
  }
}
