import 'package:firebase_analytics/firebase_analytics.dart';
import '../../../models/product_model.dart';
import '../../../models/order_model.dart';
import '../../../models/cart_item_model.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logAddToCart(ProductModel product, double quantity) async {
    await _analytics.logEvent(
      name: 'add_to_cart',
      parameters: {
        'product_id': product.id,
        'product_name': product.name,
        'category': product.category,
        'price': product.pricePerKg,
        'quantity': quantity,
      },
    );
  }

  Future<void> logBeginCheckout(int itemCount, double totalValue) async {
    await _analytics.logEvent(
      name: 'begin_checkout',
      parameters: {
        'value': totalValue,
        'currency': 'RSD',
        'item_count': itemCount,
      },
    );
  }

  Future<void> logPurchase({
    required String transactionId,
    required double value,
    required int itemCount,
    double? shipping,
  }) async {
    await _analytics.logEvent(
      name: 'purchase',
      parameters: {
        'transaction_id': transactionId,
        'value': value,
        'currency': 'RSD',
        if (shipping != null) 'shipping': shipping,
        'item_count': itemCount,
      },
    );
  }
}
