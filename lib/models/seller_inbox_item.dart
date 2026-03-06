/// Stavka u jedinstvenom inbox-u prodavca – porudžbina ili razgovor
enum SellerInboxItemType { order, conversation }

class SellerInboxItem {
  final SellerInboxItemType type;
  final DateTime sortDate;
  final String? orderId;
  final String? conversationId;
  final String? buyerId;
  final String? otherPartyName;
  final String? otherPartyImageUrl;
  final String? productName;
  final double? quantityKg;
  final String? unitType;
  final String? lastMessageBody;
  final int unreadCount;
  final String? statusLabel;
  final String? buyerPhone;
  final String? note;
  final String? buyerCity;
  final String? buyerAddress;

  const SellerInboxItem({
    required this.type,
    required this.sortDate,
    this.orderId,
    this.conversationId,
    this.buyerId,
    this.otherPartyName,
    this.otherPartyImageUrl,
    this.productName,
    this.quantityKg,
    this.unitType,
    this.lastMessageBody,
    this.unreadCount = 0,
    this.statusLabel,
    this.buyerPhone,
    this.note,
    this.buyerCity,
    this.buyerAddress,
  });
}
