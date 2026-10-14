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

  /// Prilagođene, korisnički razumljive poruke o greškama pri kreiranju porudžbine.
  static String friendlySubmitError(Object e) {
    final s = e.toString();
    if (s.contains('seller cannot buy own products')) {
      return 'Nije moguće poručiti sopstvene proizvode.';
    }
    if (s.contains('must follow order step')) {
      return 'Količina mora biti usklađena sa korakom porudžbine za izabrani proizvod.';
    }
    if (s.contains('exceeds available stock')) {
      return 'Izabrana količina prevazilazi trenutno dostupnu zalihu.';
    }
    if (s.contains('honey products must use kg unit')) {
      return 'Med se može poručiti samo u kilogramima.';
    }
    if (s.contains('invalid delivery_method')) {
      return 'Izabrani način dostave privremeno nije dostupan. Pokušaj ponovo.';
    }
    if (s.contains('is currently unavailable')) {
      return 'Jedan od proizvoda trenutno nije dostupan.';
    }
    if (s.contains('below min_order')) {
      return 'Količina je ispod minimalne porudžbine za jedan od proizvoda.';
    }
    if (s.contains('below delivery slot minimum')) {
      return 'Ukupan iznos nije dostigao minimum za izabrani termin dostave.';
    }
    if (s.contains('SocketException') ||
        s.contains('network') ||
        s.contains('XMLHttpRequest')) {
      return 'Nema internet veze. Proveri konekciju i pokušaj ponovo.';
    }
    return 'Došlo je do greške prilikom slanja porudžbine. Pokušaj ponovo.';
  }
}
