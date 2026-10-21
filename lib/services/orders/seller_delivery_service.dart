import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/seller_delivery_models.dart';
import '../../repositories/orders/seller_delivery_repository.dart';

class SellerDeliveryService {
  static final SellerDeliveryService _instance =
      SellerDeliveryService._internal();

  factory SellerDeliveryService({
    SellerDeliveryRepository? repository,
    SupabaseClient? client,
  }) {
    if (repository != null || client != null) {
      return SellerDeliveryService._(repository: repository, client: client);
    }
    return _instance;
  }

  SellerDeliveryService._({
    SellerDeliveryRepository? repository,
    SupabaseClient? client,
  }) : _repository =
            repository ?? SupabaseSellerDeliveryRepository(client: client);

  SellerDeliveryService._internal()
      : _repository = SupabaseSellerDeliveryRepository();

  final SellerDeliveryRepository _repository;

  Future<List<SellerDeliveryPointModel>> getSellerDeliveryPoints(
    String sellerId, {
    bool onlyActive = false,
  }) async {
    return _repository.getSellerDeliveryPoints(sellerId, onlyActive: onlyActive);
  }

  Future<SellerDeliveryPointModel> createDeliveryPoint(
    SellerDeliveryPointModel point,
  ) async {
    return _repository.createDeliveryPoint(point);
  }

  Future<SellerDeliveryPointModel> updateDeliveryPoint(
    SellerDeliveryPointModel point,
  ) async {
    return _repository.updateDeliveryPoint(point);
  }

  Future<void> deleteDeliveryPoint(String pointId) async {
    await _repository.deleteDeliveryPoint(pointId);
  }

  Future<SellerDeliverySlotModel> createDeliverySlot(
    SellerDeliverySlotModel slot,
  ) async {
    return _repository.createDeliverySlot(slot);
  }

  Future<SellerDeliverySlotModel> updateDeliverySlot(
    SellerDeliverySlotModel slot,
  ) async {
    return _repository.updateDeliverySlot(slot);
  }

  Future<void> deleteDeliverySlot(String slotId) async {
    await _repository.deleteDeliverySlot(slotId);
  }
}

