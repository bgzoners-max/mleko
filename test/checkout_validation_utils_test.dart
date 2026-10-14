import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/seller_delivery_models.dart';
import 'package:mleko/widgets/checkout/checkout_validation_utils.dart';

void main() {
  group('CheckoutValidationUtils - formatMissingFields', () {
    test('returns empty string for empty list', () {
      expect(CheckoutValidationUtils.formatMissingFields([]), '');
    });

    test('formats single field correctly', () {
      expect(
        CheckoutValidationUtils.formatMissingFields(['adresu']),
        'Niste uneli adresu.',
      );
    });

    test('formats two fields with i conjunction', () {
      expect(
        CheckoutValidationUtils.formatMissingFields(['adresu', 'grad']),
        'Niste uneli adresu i grad.',
      );
    });

    test('formats multiple fields with commas and i conjunction', () {
      expect(
        CheckoutValidationUtils.formatMissingFields([
          'adresu',
          'grad',
          'poštanski broj',
          'kontakt telefon',
        ]),
        'Niste uneli adresu, grad, poštanski broj i kontakt telefon.',
      );
    });
  });

  group('CheckoutValidationUtils - validateBuyerDeliveryFields', () {
    test('courier delivery: passes when all required fields are provided', () {
      final error = CheckoutValidationUtils.validateBuyerDeliveryFields(
        deliveryMethod: DeliveryMethod.courier,
        phone: '0601234567',
        city: 'Beograd',
        address: 'Knez Mihailova 1',
      );
      expect(error, isNull);
    });

    test('courier delivery: fails when address, city, and phone are missing', () {
      final error = CheckoutValidationUtils.validateBuyerDeliveryFields(
        deliveryMethod: DeliveryMethod.courier,
        phone: '',
        city: '',
        address: '',
      );
      expect(error, 'Niste uneli adresu, grad i kontakt telefon.');
    });

    test('courier delivery: requires postal code when requirePostalCode is true', () {
      final error = CheckoutValidationUtils.validateBuyerDeliveryFields(
        deliveryMethod: DeliveryMethod.courier,
        phone: '0601234567',
        city: 'Novi Sad',
        address: 'Bulevar 10',
        postalCode: '',
        requirePostalCode: true,
      );
      expect(error, 'Niste uneli poštanski broj.');
    });

    test('seller delivery: passes when slot is selected and phone is provided', () {
      const selection = DeliverySelectionModel(
        method: DeliveryMethod.sellerDelivery,
        pointId: 'point-1',
        slotId: 'slot-1',
        city: 'Beograd',
        pointLabel: 'Pijaca Kalenić',
        address: 'Maksima Gorkog bb',
        weekday: 2,
        timeFrom: '08:00',
        timeTo: '12:00',
      );

      final error = CheckoutValidationUtils.validateBuyerDeliveryFields(
        deliveryMethod: DeliveryMethod.sellerDelivery,
        phone: '0612345678',
        city: '',
        address: '',
        deliverySelection: selection,
      );
      expect(error, isNull);
    });

    test('seller delivery: fails when slot selection is missing', () {
      final error = CheckoutValidationUtils.validateBuyerDeliveryFields(
        deliveryMethod: DeliveryMethod.sellerDelivery,
        phone: '0612345678',
        city: '',
        address: '',
        deliverySelection: null,
      );
      expect(
        error,
        'Izaberi grad, lokaciju i termin za ličnu dostavu domaćina.',
      );
    });
  });

  group('CheckoutValidationUtils - friendlySubmitError', () {
    test('translates seller buying own products error', () {
      final msg = CheckoutValidationUtils.friendlySubmitError(
        Exception('Postgres error: seller cannot buy own products'),
      );
      expect(msg, 'Nije moguće poručiti sopstvene proizvode.');
    });

    test('translates order step violation', () {
      final msg = CheckoutValidationUtils.friendlySubmitError(
        'Exception: quantity must follow order step for product',
      );
      expect(
        msg,
        'Količina mora biti usklađena sa korakom porudžbine za izabrani proizvod.',
      );
    });

    test('translates stock excess error', () {
      final msg = CheckoutValidationUtils.friendlySubmitError(
        'DatabaseException: exceeds available stock',
      );
      expect(msg, 'Izabrana količina prevazilazi trenutno dostupnu zalihu.');
    });

    test('translates honey unit error', () {
      final msg = CheckoutValidationUtils.friendlySubmitError(
        'honey products must use kg unit',
      );
      expect(msg, 'Med se može poručiti samo u kilogramima.');
    });

    test('translates invalid delivery method', () {
      final msg = CheckoutValidationUtils.friendlySubmitError(
        'invalid delivery_method provided',
      );
      expect(
        msg,
        'Izabrani način dostave privremeno nije dostupan. Pokušaj ponovo.',
      );
    });

    test('translates currently unavailable product', () {
      final msg = CheckoutValidationUtils.friendlySubmitError(
        'product is currently unavailable',
      );
      expect(msg, 'Jedan od proizvoda trenutno nije dostupan.');
    });

    test('translates below min_order', () {
      final msg = CheckoutValidationUtils.friendlySubmitError(
        'order total below min_order threshold',
      );
      expect(
        msg,
        'Količina je ispod minimalne porudžbine za jedan od proizvoda.',
      );
    });

    test('translates below delivery slot minimum', () {
      final msg = CheckoutValidationUtils.friendlySubmitError(
        'below delivery slot minimum price',
      );
      expect(
        msg,
        'Ukupan iznos nije dostigao minimum za izabrani termin dostave.',
      );
    });

    test('translates network and socket exceptions', () {
      expect(
        CheckoutValidationUtils.friendlySubmitError('SocketException: failed'),
        'Nema internet veze. Proveri konekciju i pokušaj ponovo.',
      );
      expect(
        CheckoutValidationUtils.friendlySubmitError('network connection lost'),
        'Nema internet veze. Proveri konekciju i pokušaj ponovo.',
      );
      expect(
        CheckoutValidationUtils.friendlySubmitError('XMLHttpRequest error'),
        'Nema internet veze. Proveri konekciju i pokušaj ponovo.',
      );
    });

    test('returns generic message for unknown errors', () {
      final msg = CheckoutValidationUtils.friendlySubmitError(
        'Something completely unexpected happened 500',
      );
      expect(
        msg,
        'Došlo je do greške prilikom slanja porudžbine. Pokušaj ponovo.',
      );
    });
  });
}
