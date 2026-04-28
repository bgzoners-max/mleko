import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/order_item_model.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../../models/seller_delivery_models.dart';
import '../../../models/app_error.dart';
import '../../../utils/quantity_engine.dart';
import '../../../utils/search_utils.dart'; // for formatRsdAmount if it exists there, but usually it's in a more common place

mixin OrderManagementMixin {
  SupabaseClient get client;

  Future<String> createSingleProductOrder({
    required String buyerId,
    required String sellerId,
    required String productId,
    required String productName,
    required double quantityKg,
    required String unitType,
    required String note,
    required String buyerCity,
    required String buyerPhone,
    String? buyerAddress,
    String? buyerPostalCode,
    DeliveryMethod deliveryMethod = DeliveryMethod.agreement,
    DeliverySelectionModel? deliverySelection,
  }) {
    return createOrderWithItems(
      buyerId: buyerId,
      sellerId: sellerId,
      items: [
        OrderItemModel(
          productId: productId,
          productName: productName,
          quantityKg: quantityKg,
          unitType: unitType,
        ),
      ],
      note: note,
      buyerCity: buyerCity,
      buyerPhone: buyerPhone,
      buyerAddress: buyerAddress,
      buyerPostalCode: buyerPostalCode,
      deliveryMethod: deliveryMethod,
      deliverySelection: deliverySelection,
    );
  }

  Future<String> createOrderWithItems({
    required String buyerId,
    required String sellerId,
    required List<OrderItemModel> items,
    required String note,
    required String buyerCity,
    required String buyerPhone,
    String? buyerAddress,
    String? buyerPostalCode,
    DeliveryMethod deliveryMethod = DeliveryMethod.agreement,
    DeliverySelectionModel? deliverySelection,
  }) async {
    if (items.isEmpty) {
      throw AppError(
        message: 'Empty order items',
        userMessage: 'Porudžbina mora imati barem jednu stavku.',
        type: ErrorType.validation,
      );
    }

    final productIds = items.map((e) => e.productId).toSet().toList();
    final products = await client
        .from('products')
        .select(
            'id, seller_id, name, category, unit_type, min_order_kg, order_step, price_per_kg')
        .inFilter('id', productIds);
    final productMap = {
      for (final p in (products as List).cast<Map<String, dynamic>>())
        (p['id'] as String): p,
    };

    var orderTotal = 0.0;

    for (final item in items) {
      final product = productMap[item.productId];
      if (product == null) {
        throw AppError(
          message: 'Product not found: ${item.productId}',
          userMessage: 'Proizvod više nije dostupan.',
          type: ErrorType.notFound,
        );
      }

      if ((product['seller_id'] as String?) != sellerId) {
        throw AppError(
          message: 'Seller mismatch for item ${item.productId}',
          userMessage: 'Stavke moraju pripadati istom prodavcu.',
          type: ErrorType.validation,
        );
      }

      final unitType = (product['unit_type'] as String?) ?? ProductModel.unitKg;
      final minQuantity = (product['min_order_kg'] as num?)?.toDouble() ?? 0;
      final explicitStep = (product['order_step'] as num?)?.toDouble();
      final name = (product['name'] as String?) ?? '';
      final normalizedUnit =
          unitType == ProductModel.unitG ? ProductModel.unitKg : unitType;
      final step = (explicitStep != null && explicitStep > 0)
          ? explicitStep
          : (unitType == ProductModel.unitPiece
              ? 10.0
              : unitType == ProductModel.unitL
                  ? 1.0
                  : 0.5);

      if (!QuantityEngine.isValidQuantity(
        quantity: item.quantityKg,
        minQuantity: minQuantity,
        step: step,
      )) {
        throw AppError(
          message: 'Invalid quantity for $name',
          userMessage:
              '$name: količina mora biti od minimuma i u koracima od ${ProductModel.formatQuantityWithUnit(step, normalizedUnit)}.',
          type: ErrorType.validation,
        );
      }

      final unitPrice = (product['price_per_kg'] as num?)?.toDouble() ?? 0;
      orderTotal += unitPrice * item.quantityKg;
    }

    if (deliveryMethod == DeliveryMethod.sellerDelivery) {
      if (deliverySelection == null) {
        throw AppError(
          message: 'Delivery selection missing',
          userMessage: 'Izaberite grad, lokaciju i termin lične dostave.',
          type: ErrorType.validation,
        );
      }
      final minimum = deliverySelection.minOrderAmountRsd;
      if (minimum != null && orderTotal < minimum) {
        throw AppError(
          message: 'Order total below delivery minimum',
          userMessage:
              'Minimalna porudžbina za izabrani termin je ${formatRsdAmount(minimum)}.',
          type: ErrorType.validation,
        );
      }
    }

    try {
      final itemsJson = items.map((i) => i.toJson()).toList();
      final result = await client.rpc(
        'create_order_with_items',
        params: {
          'p_buyer_id': buyerId,
          'p_seller_id': sellerId,
          'p_buyer_phone': buyerPhone,
          'p_items': itemsJson,
          'p_note': note,
          'p_buyer_city': buyerCity,
          'p_buyer_address': buyerAddress,
          'p_buyer_postal_code': buyerPostalCode,
          'p_delivery_method': deliveryMethod.dbValue,
          'p_delivery_point_id': deliverySelection?.pointId,
          'p_delivery_slot_id': deliverySelection?.slotId,
          'p_delivery_fee_rsd': deliverySelection?.deliveryFeeRsd,
        },
      );
      return result as String;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await client
          .from('orders')
          .update({'status': status.dbValue}).eq('id', orderId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> cancelOrderBySeller(String orderId, String reason) async {
    try {
      await client.from('orders').update({
        'status': OrderStatus.cancelledBySeller.dbValue,
        'cancellation_reason': reason.trim().isEmpty ? null : reason.trim(),
      }).eq('id', orderId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> archiveOrderByBuyer(String buyerId, String orderId) async {
    try {
      await client
          .from('orders')
          .update({
            'status': OrderStatus.archived.dbValue,
            'archived_at': DateTime.now().toUtc().toIso8601String(),
            'expires_at': DateTime.now()
                .toUtc()
                .add(const Duration(days: 365))
                .toIso8601String(),
          })
          .eq('id', orderId)
          .eq('buyer_id', buyerId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> archiveOrderBySeller(String sellerId, String orderId) async {
    try {
      await client
          .from('orders')
          .update({
            'status': OrderStatus.archived.dbValue,
            'archived_at': DateTime.now().toUtc().toIso8601String(),
            'expires_at': DateTime.now()
                .toUtc()
                .add(const Duration(days: 365))
                .toIso8601String(),
          })
          .eq('id', orderId)
          .eq('seller_id', sellerId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> confirmOrderReceivedByBuyer(String orderId) async {
    try {
      final result = await client.rpc(
        'buyer_confirm_order_received',
        params: {'p_order_id': orderId},
      );
      if (result != true) {
        throw AppError(
          message: 'Confirmation failed',
          userMessage: 'Nije moguće potvrditi prijem za ovu porudžbinu.',
          type: ErrorType.validation,
        );
      }
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
