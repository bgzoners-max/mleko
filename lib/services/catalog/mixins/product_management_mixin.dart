import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/product_model.dart';
import '../../../models/app_error.dart';

mixin ProductManagementMixin {
  SupabaseClient get client;

  Future<void> setProductDeliveryScope(
    String productId,
    ProductDeliveryMode deliveryMode,
    List<String> selectedDeliveryPointIds,
  ) async {
    final normalizedDeliveryPointIds = selectedDeliveryPointIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (deliveryMode == ProductDeliveryMode.selectedPoints &&
        normalizedDeliveryPointIds.isEmpty) {
      throw AppError(
        message: 'No delivery points selected',
        userMessage: 'Morate izabrati barem jedno mesto isporuke.',
        type: ErrorType.validation,
      );
    }

    try {
      await client.rpc(
        'set_product_delivery_scope',
        params: {
          'p_product_id': productId,
          'p_delivery_mode': deliveryMode.dbValue,
          'p_delivery_point_ids':
              deliveryMode == ProductDeliveryMode.selectedPoints
                  ? normalizedDeliveryPointIds
                  : <String>[],
        },
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<String> addProduct(ProductModel product) async {
    try {
      final data = Map<String, dynamic>.from(product.toJson());
      if ((data['id'] as String?)?.trim().isEmpty ?? true) {
        data.remove('id');
      }
      data['delivery_mode'] = ProductDeliveryMode.none.dbValue;
      final res =
          await client.from('products').insert(data).select('id').single();
      final productId = (res)['id'] as String;
      await setProductDeliveryScope(
        productId,
        product.deliveryMode,
        product.selectedDeliveryPointIds,
      );
      return productId;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      final data = Map<String, dynamic>.from(product.toJson())
        ..remove('delivery_mode');
      await client.from('products').update(data).eq('id', product.id);
      await setProductDeliveryScope(
        product.id,
        product.deliveryMode,
        product.selectedDeliveryPointIds,
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await client.from('products').delete().eq('id', id);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> updateAvailableNow(String productId, bool availableNow) async {
    try {
      await client
          .from('products')
          .update({'available_now': availableNow}).eq('id', productId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
