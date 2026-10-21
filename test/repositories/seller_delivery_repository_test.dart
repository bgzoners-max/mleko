import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/seller_delivery_models.dart';
import 'package:mleko/repositories/orders/seller_delivery_repository.dart';
import 'package:mleko/services/orders/seller_delivery_service.dart';

class FakeSellerDeliveryRepository implements SellerDeliveryRepository {
  final List<SellerDeliveryPointModel> points = [];
  final List<SellerDeliverySlotModel> slots = [];

  @override
  Future<List<SellerDeliveryPointModel>> getSellerDeliveryPoints(
    String sellerId, {
    bool onlyActive = false,
  }) async {
    return points
        .where((p) => p.sellerId == sellerId && (!onlyActive || p.isActive))
        .toList();
  }

  @override
  Future<SellerDeliveryPointModel> createDeliveryPoint(
    SellerDeliveryPointModel point,
  ) async {
    points.add(point);
    return point;
  }

  @override
  Future<SellerDeliveryPointModel> updateDeliveryPoint(
    SellerDeliveryPointModel point,
  ) async {
    points.removeWhere((p) => p.id == point.id);
    points.add(point);
    return point;
  }

  @override
  Future<void> deleteDeliveryPoint(String pointId) async {
    points.removeWhere((p) => p.id == pointId);
  }

  @override
  Future<SellerDeliverySlotModel> createDeliverySlot(
    SellerDeliverySlotModel slot,
  ) async {
    slots.add(slot);
    return slot;
  }

  @override
  Future<SellerDeliverySlotModel> updateDeliverySlot(
    SellerDeliverySlotModel slot,
  ) async {
    slots.removeWhere((s) => s.id == slot.id);
    slots.add(slot);
    return slot;
  }

  @override
  Future<void> deleteDeliverySlot(String slotId) async {
    slots.removeWhere((s) => s.id == slotId);
  }
}

void main() {
  group('SellerDeliveryRepository & SellerDeliveryService test', () {
    late FakeSellerDeliveryRepository fakeRepo;
    late SellerDeliveryService service;

    setUp(() {
      fakeRepo = FakeSellerDeliveryRepository();
      service = SellerDeliveryService(repository: fakeRepo);
    });

    test('createDeliveryPoint i getSellerDeliveryPoints rade bez Supabase baze',
        () async {
      const point = SellerDeliveryPointModel(
        id: 'pt-1',
        sellerId: 's1',
        city: 'Beograd',
        label: 'Kalenić pijaca',
        address: 'Maksima Gorkog bb',
        isActive: true,
      );

      await service.createDeliveryPoint(point);

      final result = await service.getSellerDeliveryPoints('s1');
      expect(result.length, 1);
      expect(result.first.label, 'Kalenić pijaca');
    });

    test('deleteDeliveryPoint uklanja tačku isporuke', () async {
      const point = SellerDeliveryPointModel(
        id: 'pt-2',
        sellerId: 's1',
        city: 'Novi Sad',
        label: 'Futoška pijaca',
        address: 'Jevrejska bb',
        isActive: true,
      );
      await service.createDeliveryPoint(point);

      await service.deleteDeliveryPoint('pt-2');
      final result = await service.getSellerDeliveryPoints('s1');
      expect(result, isEmpty);
    });
  });
}
