import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/seller_delivery_models.dart';

void main() {
  group('Seller Delivery Models & Helpers', () {
    test('DeliveryMethod extension values and labels', () {
      expect(DeliveryMethod.courier.dbValue, 'courier');
      expect(DeliveryMethod.courier.label, 'Kurirska služba');
      expect(DeliveryMethod.pickup.dbValue, 'pickup');
      expect(DeliveryMethod.pickup.label, 'Lično preuzimanje');
      expect(DeliveryMethod.sellerDelivery.dbValue, 'seller_delivery');
      expect(DeliveryMethod.sellerDelivery.label, 'Dostava od strane prodavca');
      expect(DeliveryMethod.agreement.dbValue, 'agreement');
      expect(DeliveryMethod.agreement.label, 'Dogovor sa domaćinom');
    });

    test('deliveryMethodFromDb parses valid and unknown db values', () {
      expect(deliveryMethodFromDb('courier'), DeliveryMethod.courier);
      expect(deliveryMethodFromDb('pickup'), DeliveryMethod.pickup);
      expect(deliveryMethodFromDb('seller_delivery'), DeliveryMethod.sellerDelivery);
      expect(deliveryMethodFromDb('agreement'), DeliveryMethod.agreement);
      expect(deliveryMethodFromDb('unknown'), DeliveryMethod.courier);
      expect(deliveryMethodFromDb(null), DeliveryMethod.courier);
    });

    test('sellerDeliveryWeekdayLabel returns correct names and handles out of range', () {
      expect(sellerDeliveryWeekdayLabel(1), 'Ponedeljak');
      expect(sellerDeliveryWeekdayLabel(2), 'Utorak');
      expect(sellerDeliveryWeekdayLabel(3), 'Sreda');
      expect(sellerDeliveryWeekdayLabel(4), 'Četvrtak');
      expect(sellerDeliveryWeekdayLabel(5), 'Petak');
      expect(sellerDeliveryWeekdayLabel(6), 'Subota');
      expect(sellerDeliveryWeekdayLabel(7), 'Nedelja');
      expect(sellerDeliveryWeekdayLabel(0), 'Nepoznat dan');
      expect(sellerDeliveryWeekdayLabel(8), 'Nepoznat dan');
    });

    test('normalizeDeliveryTimeString pads and formats hours and minutes', () {
      expect(normalizeDeliveryTimeString('9:5'), '09:05');
      expect(normalizeDeliveryTimeString('09:30'), '09:30');
      expect(normalizeDeliveryTimeString(''), '');
      expect(normalizeDeliveryTimeString(null), '');
      expect(normalizeDeliveryTimeString('invalid'), 'invalid');
    });

    test('formatDeliveryWindow formats start and end times', () {
      expect(formatDeliveryWindow('9:0', '11:0'), '09:00 - 11:00');
    });

    test('formatRsdAmount formats integer and decimal amounts', () {
      expect(formatRsdAmount(null), isNull);
      expect(formatRsdAmount(250.0), '250 din.');
      expect(formatRsdAmount(250.50), '250,50 din.');
    });

    test('SellerDeliverySlotModel serialization, update, and labels', () {
      final json = {
        'id': 'slot_1',
        'delivery_point_id': 'point_1',
        'weekday': 2,
        'time_from': '9:00',
        'time_to': '13:00',
        'delivery_fee_rsd': 200,
        'min_order_amount_rsd': 1000,
        'max_orders': 15,
        'is_active': true,
        'created_at': '2026-01-01T10:00:00Z',
        'updated_at': '2026-01-02T10:00:00Z',
      };

      final slot = SellerDeliverySlotModel.fromJson(json);
      expect(slot.id, 'slot_1');
      expect(slot.weekdayLabel, 'Utorak');
      expect(slot.timeRangeLabel, '09:00 - 13:00');

      final insertJson = slot.toInsertJson();
      expect(insertJson['weekday'], 2);
      expect(insertJson['time_from'], '09:00');
      expect(insertJson['delivery_fee_rsd'], 200.0);

      final updateJson = slot.toUpdateJson();
      expect(updateJson.containsKey('updated_at'), isTrue);
      expect(updateJson['delivery_point_id'], 'point_1');
    });

    test('SellerDeliveryPointModel activeSlots sorting and copyWith', () {
      const slot1 = SellerDeliverySlotModel(
        id: 'slot_1',
        deliveryPointId: 'point_1',
        weekday: 5,
        timeFrom: '14:00',
        timeTo: '16:00',
      );
      const slot2 = SellerDeliverySlotModel(
        id: 'slot_2',
        deliveryPointId: 'point_1',
        weekday: 2,
        timeFrom: '09:00',
        timeTo: '11:00',
      );
      const slot3Inactive = SellerDeliverySlotModel(
        id: 'slot_3',
        deliveryPointId: 'point_1',
        weekday: 1,
        timeFrom: '08:00',
        timeTo: '10:00',
        isActive: false,
      );

      final point = const SellerDeliveryPointModel(
        id: 'point_1',
        sellerId: 'seller_123',
        city: 'Beograd',
        label: 'Kalenić',
        address: 'Maksima Gorkog bb',
        slots: [slot1, slot2, slot3Inactive],
      );

      expect(point.summaryLabel, 'Kalenić, Maksima Gorkog bb');

      final active = point.activeSlots;
      expect(active.length, 2);
      // Tuesday (2) should be before Friday (5)
      expect(active[0].id, 'slot_2');
      expect(active[1].id, 'slot_1');

      final pointUpdated = point.copyWith(slots: [slot1]);
      expect(pointUpdated.slots.length, 1);
      expect(pointUpdated.city, 'Beograd');

      final insertJson = point.toInsertJson();
      expect(insertJson['seller_id'], 'seller_123');
      expect(insertJson['city'], 'Beograd');

      final updateJson = point.toUpdateJson();
      expect(updateJson.containsKey('updated_at'), isTrue);
    });

    test('DeliverySelectionModel fromPointAndSlot and getters', () {
      const slot = SellerDeliverySlotModel(
        id: 'slot_10',
        deliveryPointId: 'point_20',
        weekday: 6,
        timeFrom: '08:00',
        timeTo: '12:00',
        deliveryFeeRsd: 150.0,
        minOrderAmountRsd: 800.0,
      );
      const point = SellerDeliveryPointModel(
        id: 'point_20',
        sellerId: 'seller_1',
        city: 'Novi Sad',
        label: 'Riblja pijaca',
        address: 'Trg republike 1',
      );

      final selection = DeliverySelectionModel.fromPointAndSlot(point, slot);
      expect(selection.method, DeliveryMethod.sellerDelivery);
      expect(selection.city, 'Novi Sad');
      expect(selection.scheduleLabel, 'Subota, 08:00 - 12:00');
      expect(selection.feeLabel, '150 din.');
      expect(selection.minOrderLabel, '800 din.');
    });
  });
}
