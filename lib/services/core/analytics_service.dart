import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../models/classified_ad_model.dart';
import '../../models/product_model.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService({FirebaseAnalytics? analytics}) {
    if (analytics != null) {
      return AnalyticsService._withAnalytics(analytics);
    }
    return _instance;
  }
  AnalyticsService._internal() : _customAnalytics = null;
  AnalyticsService._withAnalytics(FirebaseAnalytics analytics)
      : _customAnalytics = analytics;

  final FirebaseAnalytics? _customAnalytics;

  FirebaseAnalytics? get _analytics {
    if (_customAnalytics != null) return _customAnalytics;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAnalytics.instance;
      }
    } catch (_) {}
    return null;
  }

  Future<void> logViewProduct(ProductModel product) async {
    try {
      await _analytics?.logViewItem(
        currency: 'RSD',
        value: product.pricePerKg,
        items: [
          AnalyticsEventItem(
            itemId: product.id,
            itemName: product.name,
            itemCategory: product.category,
            price: product.pricePerKg,
          ),
        ],
      );
    } catch (_) {}
  }

  Future<void> logViewClassifiedAd(ClassifiedAdModel ad) async {
    try {
      await _analytics?.logEvent(
        name: 'view_classified_ad',
        parameters: {
          'ad_id': ad.id,
          'title': ad.title,
          'category': ad.categoryId,
          'price': ad.price,
          'currency': ad.currency,
        },
      );
    } catch (_) {}
  }

  Future<void> logAddToCart(ProductModel product, double quantity) async {
    try {
      await _analytics?.logEvent(
        name: 'add_to_cart',
        parameters: {
          'product_id': product.id,
          'product_name': product.name,
          'category': product.category,
          'price': product.pricePerKg,
          'quantity': quantity,
        },
      );
    } catch (_) {}
  }

  Future<void> logBeginCheckout(int itemCount, double totalValue) async {
    try {
      await _analytics?.logEvent(
        name: 'begin_checkout',
        parameters: {
          'value': totalValue,
          'currency': 'RSD',
          'item_count': itemCount,
        },
      );
    } catch (_) {}
  }

  Future<void> logPurchase({
    required String transactionId,
    required double value,
    required int itemCount,
    double? shipping,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'purchase',
        parameters: {
          'transaction_id': transactionId,
          'value': value,
          'currency': 'RSD',
          if (shipping != null) 'shipping': shipping,
          'item_count': itemCount,
        },
      );
    } catch (_) {}
  }
}
