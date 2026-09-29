import 'product_model.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final double quantityKg;
  final String unitType;
  /// Cena po jedinici (kg/L) pri slanju porudžbine; za upis u order_items.unit_price
  final double unitPrice;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantityKg,
    this.unitType = ProductModel.unitKg,
    this.unitPrice = 0,
  });

  double get totalPrice => unitPrice * quantityKg;

  /// Ukupna količina po jedinicama za prikaz (npr. "7.5 kg + 3 L + 650 g + 30 kom + 2 veza + 1 pak").
  static String totalQuantityLabel(List<OrderItemModel> items) {
    double totalKg = 0, totalL = 0, totalGkg = 0, totalPieces = 0, totalVeza = 0, totalPak = 0;
    for (final item in items) {
      switch (item.unitType) {
        case ProductModel.unitL:
          totalL += item.quantityKg;
          break;
        case ProductModel.unitG:
          totalGkg += item.quantityKg;
          break;
        case ProductModel.unitPiece:
          totalPieces += item.quantityKg;
          break;
        case ProductModel.unitVeza:
          totalVeza += item.quantityKg;
          break;
        case ProductModel.unitPak:
          totalPak += item.quantityKg;
          break;
        default:
          totalKg += item.quantityKg;
      }
    }
    final parts = <String>[];
    if (totalKg > 0) parts.add(ProductModel.formatQuantityWithUnit(totalKg, ProductModel.unitKg));
    if (totalL > 0) parts.add(ProductModel.formatQuantityWithUnit(totalL, ProductModel.unitL));
    if (totalGkg > 0) parts.add(ProductModel.formatQuantityWithUnit(totalGkg, ProductModel.unitG));
    if (totalPieces > 0) parts.add(ProductModel.formatQuantityWithUnit(totalPieces, ProductModel.unitPiece));
    if (totalVeza > 0) parts.add(ProductModel.formatQuantityWithUnit(totalVeza, ProductModel.unitVeza));
    if (totalPak > 0) parts.add(ProductModel.formatQuantityWithUnit(totalPak, ProductModel.unitPak));
    if (parts.isEmpty) return '';
    return 'Ukupno količina: ${parts.join(' + ')}';
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'quantity_kg': quantityKg,
        'unit_type': unitType,
        'unit_price': unitPrice,
        'total_price': totalPrice,
      };

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        productId: json['product_id'] as String? ?? '',
        productName: json['product_name'] as String? ?? '',
        quantityKg: (json['quantity_kg'] as num?)?.toDouble() ?? 0,
        unitType: json['unit_type'] as String? ?? ProductModel.unitKg,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      );
}
