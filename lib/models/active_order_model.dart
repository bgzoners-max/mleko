/// Jedna stavka aktivne porudžbine (u memoriji, pre slanja).
class ActiveOrderItem {
  final String productId;
  final String name;
  final double unitPrice;
  double quantity;

  ActiveOrderItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  double get total => unitPrice * quantity;

  ActiveOrderItem copyWith({double? quantity}) {
    return ActiveOrderItem(
      productId: productId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Aktivna porudžbina kod jednog prodavca (u memoriji).
/// Jedan ActiveOrder po prodavcu; ne upisuje se u bazu dok se ne klikne "Pošalji porudžbinu".
class ActiveOrder {
  final String sellerId;
  final String sellerName;
  final List<ActiveOrderItem> items;

  const ActiveOrder({
    required this.sellerId,
    required this.sellerName,
    required this.items,
  });

  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + item.total);

  int get itemCount => items.length;
}
