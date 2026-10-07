import '../../models/seller_delivery_models.dart';

/// Centralizovana pomoćna klasa za validaciju podataka na checkout ekranima
class CheckoutValidationUtils {
  const CheckoutValidationUtils._();

  /// Formatira listu nedostajućih polja u gramatički ispravnu rečenicu na srpskom:
  /// npr. ["adresu", "grad"] -> "Niste uneli adresu i grad."
  static String formatMissingFields(List<String> fields) {
    if (fields.isEmpty) return '';
    if (fields.length == 1) return 'Niste uneli ${fields.first}.';
    final all =
        '${fields.sublist(0, fields.length - 1).join(', ')} i ${fields.last}';
    return 'Niste uneli $all.';
  }

  /// Validacija unosa kupca i načina dostave za single i multi checkout forme.
  /// Vraća poruku o grešci ako neko obavezno polje fali, ili `null` ako je sve validno.
  static String? validateBuyerDeliveryFields({
    required DeliveryMethod deliveryMethod,
    required String phone,
    required String city,
    required String address,
    String? postalCode,
    DeliverySelectionModel? deliverySelection,
    bool requirePostalCode = false,
  }) {
    final missing = <String>[];

    if (deliveryMethod == DeliveryMethod.courier) {
      if (address.trim().isEmpty) missing.add('adresu');
      if (city.trim().isEmpty) missing.add('grad');
      if (requirePostalCode &&
          (postalCode == null || postalCode.trim().isEmpty)) {
        missing.add('poštanski broj');
      }
    }

    if (phone.trim().isEmpty) {
      missing.add('kontakt telefon');
    }

    if (missing.isNotEmpty) {
      return formatMissingFields(missing);
    }

    if (deliveryMethod == DeliveryMethod.sellerDelivery &&
        deliverySelection == null) {
      return 'Izaberi grad, lokaciju i termin za ličnu dostavu domaćina.';
    }

    return null;
  }
}
