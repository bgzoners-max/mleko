import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/order_model.dart';
import 'package:mleko/models/seller_delivery_models.dart';
import 'package:mleko/widgets/checkout/buyer_form.dart';
import 'package:mleko/widgets/checkout/checkout_validation_utils.dart';
import 'package:mleko/widgets/checkout/delivery_selector.dart';

void main() {
  group('OrderModel.copyWith Tests', () {
    final originalOrder = OrderModel(
      id: 'ord-123',
      buyerId: 'buyer-abc',
      sellerId: 'seller-xyz',
      productId: 'prod-456',
      productName: 'Sveže mleko',
      quantityKg: 2.0,
      unitType: 'L',
      note: 'Ostaviti ispred vrata',
      buyerCity: 'Beograd',
      buyerPhone: '0601234567',
      buyerAddress: 'Kneza Miloša 10',
      buyerPostalCode: '11000',
      status: OrderStatus.sent,
      createdAt: DateTime(2026, 3, 1, 10, 0),
      deliveryMethod: DeliveryMethod.courier,
      totalAmount: 400.0,
      counterpartyName: 'Marko Marković',
      isReviewed: false,
    );

    test('copyWith updates status, note, and archivedAt immutably', () {
      final archivedAtDate = DateTime(2026, 3, 2, 12, 0);
      final expiresAtDate = DateTime(2027, 3, 2, 12, 0);

      final updated = originalOrder.copyWith(
        status: OrderStatus.archived,
        note: 'Ažurirana napomena',
        archivedAt: archivedAtDate,
        expiresAt: expiresAtDate,
        totalAmount: 500.0,
      );

      // Verify original is untouched
      expect(originalOrder.status, equals(OrderStatus.sent));
      expect(originalOrder.note, equals('Ostaviti ispred vrata'));
      expect(originalOrder.archivedAt, isNull);
      expect(originalOrder.expiresAt, isNull);
      expect(originalOrder.totalAmount, equals(400.0));

      // Verify updated has new values
      expect(updated.id, equals('ord-123'));
      expect(updated.buyerId, equals('buyer-abc'));
      expect(updated.status, equals(OrderStatus.archived));
      expect(updated.note, equals('Ažurirana napomena'));
      expect(updated.archivedAt, equals(archivedAtDate));
      expect(updated.expiresAt, equals(expiresAtDate));
      expect(updated.totalAmount, equals(500.0));
      expect(updated.counterpartyName, equals('Marko Marković'));
    });

    test('copyWith supports setting nullable fields to null or new values', () {
      final withCancellation = originalOrder.copyWith(
        status: OrderStatus.cancelledBySeller,
        cancellationReason: 'Nema na stanju',
        counterpartyName: null,
      );

      expect(withCancellation.status, equals(OrderStatus.cancelledBySeller));
      expect(withCancellation.cancellationReason, equals('Nema na stanju'));
      expect(withCancellation.counterpartyName, isNull);
    });
  });

  group('CheckoutValidationUtils Tests', () {
    test('formatMissingFields formats 1, 2, and 3+ fields grammatically', () {
      expect(
        CheckoutValidationUtils.formatMissingFields(['adresu']),
        equals('Niste uneli adresu.'),
      );
      expect(
        CheckoutValidationUtils.formatMissingFields(['adresu', 'grad']),
        equals('Niste uneli adresu i grad.'),
      );
      expect(
        CheckoutValidationUtils.formatMissingFields(
            ['adresu', 'grad', 'kontakt telefon']),
        equals('Niste uneli adresu, grad i kontakt telefon.'),
      );
      expect(CheckoutValidationUtils.formatMissingFields([]), isEmpty);
    });

    test('validateBuyerDeliveryFields validates courier delivery with phone and address', () {
      // Missing all
      final errAll = CheckoutValidationUtils.validateBuyerDeliveryFields(
        deliveryMethod: DeliveryMethod.courier,
        phone: '',
        city: '',
        address: '',
      );
      expect(errAll, equals('Niste uneli adresu, grad i kontakt telefon.'));

      // Missing phone only
      final errPhone = CheckoutValidationUtils.validateBuyerDeliveryFields(
        deliveryMethod: DeliveryMethod.courier,
        phone: '',
        city: 'Novi Sad',
        address: 'Bulevar 1',
      );
      expect(errPhone, equals('Niste uneli kontakt telefon.'));

      // Valid courier
      final validCourier = CheckoutValidationUtils.validateBuyerDeliveryFields(
        deliveryMethod: DeliveryMethod.courier,
        phone: '0651234567',
        city: 'Novi Sad',
        address: 'Bulevar 1',
      );
      expect(validCourier, isNull);
    });

    test('validateBuyerDeliveryFields validates pickup and seller delivery', () {
      // Pickup requires phone, doesn't require address
      final errPickupPhone = CheckoutValidationUtils.validateBuyerDeliveryFields(
        deliveryMethod: DeliveryMethod.pickup,
        phone: '',
        city: '',
        address: '',
      );
      expect(errPickupPhone, equals('Niste uneli kontakt telefon.'));

      final validPickup = CheckoutValidationUtils.validateBuyerDeliveryFields(
        deliveryMethod: DeliveryMethod.pickup,
        phone: '0651234567',
        city: '',
        address: '',
      );
      expect(validPickup, isNull);

      // Seller delivery requires slot/point selection
      final errSellerDelivery = CheckoutValidationUtils.validateBuyerDeliveryFields(
        deliveryMethod: DeliveryMethod.sellerDelivery,
        phone: '0651234567',
        city: 'Beograd',
        address: '',
        deliverySelection: null,
      );
      expect(errSellerDelivery,
          equals('Izaberi grad, lokaciju i termin za ličnu dostavu domaćina.'));
    });
  });

  group('Shared Checkout Widgets UI Tests', () {
    testWidgets('DeliverySelector renders choices and handles changes',
        (tester) async {
      DeliveryMethod currentMethod = DeliveryMethod.courier;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DeliverySelector(
                  selectedMethod: currentMethod,
                  onMethodChanged: (m) => setState(() => currentMethod = m),
                  dense: true,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Kurirska služba'), findsOneWidget);
      expect(find.text('Lično preuzimanje'), findsOneWidget);

      await tester.tap(find.text('Lično preuzimanje'));
      await tester.pumpAndSettle();

      expect(currentMethod, equals(DeliveryMethod.pickup));
    });

    testWidgets('BuyerForm renders courier fields and updates controllers',
        (tester) async {
      final addressCtrl = TextEditingController();
      final cityCtrl = TextEditingController();
      final postalCtrl = TextEditingController();
      final phoneCtrl = TextEditingController();
      final noteCtrl = TextEditingController();
      bool savePhone = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BuyerForm(
                  deliveryMethod: DeliveryMethod.courier,
                  addressController: addressCtrl,
                  cityController: cityCtrl,
                  postalCodeController: postalCtrl,
                  phoneController: phoneCtrl,
                  noteController: noteCtrl,
                  savePhoneToProfile: savePhone,
                  onSavePhoneChanged: (v) =>
                      setState(() => savePhone = v ?? false),
                  isUserLoggedIn: true,
                  showNoticeBox: true,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Adresa (ulica i broj)'), findsOneWidget);
      expect(find.text('Grad'), findsOneWidget);
      expect(find.text('Poštanski broj'), findsOneWidget);
      expect(find.text('Kontakt telefon *'), findsOneWidget);
      expect(find.text('Sačuvaj ovaj broj u profilu'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Glavna 1');
      await tester.enterText(find.byType(TextField).at(1), 'Kragujevac');
      await tester.enterText(find.byType(TextField).at(2), '34000');
      await tester.enterText(find.byType(TextField).at(3), '0641112233');

      expect(addressCtrl.text, equals('Glavna 1'));
      expect(cityCtrl.text, equals('Kragujevac'));
      expect(postalCtrl.text, equals('34000'));
      expect(phoneCtrl.text, equals('0641112233'));

      await tester.tap(find.text('Sačuvaj ovaj broj u profilu'));
      await tester.pumpAndSettle();

      expect(savePhone, isTrue);
    });
  });
}
