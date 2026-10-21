import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/seller_delivery_models.dart';

/// Interfejs repozitorijuma za rad sa mestima i terminima isporuke prodavca.
abstract interface class SellerDeliveryRepository {
  Future<List<SellerDeliveryPointModel>> getSellerDeliveryPoints(
    String sellerId, {
    bool onlyActive = false,
  });

  Future<SellerDeliveryPointModel> createDeliveryPoint(
    SellerDeliveryPointModel point,
  );

  Future<SellerDeliveryPointModel> updateDeliveryPoint(
    SellerDeliveryPointModel point,
  );

  Future<void> deleteDeliveryPoint(String pointId);

  Future<SellerDeliverySlotModel> createDeliverySlot(
    SellerDeliverySlotModel slot,
  );

  Future<SellerDeliverySlotModel> updateDeliverySlot(
    SellerDeliverySlotModel slot,
  );

  Future<void> deleteDeliverySlot(String slotId);
}

/// Supabase implementacija [SellerDeliveryRepository].
class SupabaseSellerDeliveryRepository implements SellerDeliveryRepository {
  final SupabaseClient? _customClient;

  SupabaseSellerDeliveryRepository({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<List<SellerDeliveryPointModel>> getSellerDeliveryPoints(
    String sellerId, {
    bool onlyActive = false,
  }) async {
    var pointsQuery = _client
        .from('seller_delivery_points')
        .select()
        .eq('seller_id', sellerId);
    if (onlyActive) {
      pointsQuery = pointsQuery.eq('is_active', true);
    }
    final pointRows = await pointsQuery.order('city').order('label');
    final points = (pointRows as List).cast<Map<String, dynamic>>();
    if (points.isEmpty) return const [];

    final pointIds = points.map((row) => row['id'] as String).toList();
    var slotsQuery = _client
        .from('seller_delivery_slots')
        .select()
        .inFilter('delivery_point_id', pointIds);
    if (onlyActive) {
      slotsQuery = slotsQuery.eq('is_active', true);
    }
    final slotRows = await slotsQuery.order('weekday').order('time_from');
    final slotsByPoint = <String, List<SellerDeliverySlotModel>>{};
    for (final row in (slotRows as List).cast<Map<String, dynamic>>()) {
      final slot = SellerDeliverySlotModel.fromJson(row);
      slotsByPoint.putIfAbsent(slot.deliveryPointId, () => []).add(slot);
    }

    return points
        .map((row) => SellerDeliveryPointModel.fromJson(
              row,
              slots: slotsByPoint[row['id'] as String] ?? const [],
            ))
        .where((point) => !onlyActive || point.activeSlots.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<SellerDeliveryPointModel> createDeliveryPoint(
    SellerDeliveryPointModel point,
  ) async {
    final row = await _client
        .from('seller_delivery_points')
        .insert(point.toInsertJson())
        .select()
        .single();
    return SellerDeliveryPointModel.fromJson(row);
  }

  @override
  Future<SellerDeliveryPointModel> updateDeliveryPoint(
    SellerDeliveryPointModel point,
  ) async {
    final row = await _client
        .from('seller_delivery_points')
        .update(point.toUpdateJson())
        .eq('id', point.id)
        .select()
        .single();
    return SellerDeliveryPointModel.fromJson(row, slots: point.slots);
  }

  @override
  Future<void> deleteDeliveryPoint(String pointId) async {
    await _client.from('seller_delivery_points').delete().eq('id', pointId);
  }

  @override
  Future<SellerDeliverySlotModel> createDeliverySlot(
    SellerDeliverySlotModel slot,
  ) async {
    final row = await _client
        .from('seller_delivery_slots')
        .insert(slot.toInsertJson())
        .select()
        .single();
    return SellerDeliverySlotModel.fromJson(row);
  }

  @override
  Future<SellerDeliverySlotModel> updateDeliverySlot(
    SellerDeliverySlotModel slot,
  ) async {
    final row = await _client
        .from('seller_delivery_slots')
        .update(slot.toUpdateJson())
        .eq('id', slot.id)
        .select()
        .single();
    return SellerDeliverySlotModel.fromJson(row);
  }

  @override
  Future<void> deleteDeliverySlot(String slotId) async {
    await _client.from('seller_delivery_slots').delete().eq('id', slotId);
  }
}
