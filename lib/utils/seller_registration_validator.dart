enum ProducerLegalType {
  rpg,
  company;

  String get dbValue => this == ProducerLegalType.company ? 'company' : 'rpg';

  static ProducerLegalType? fromDbValue(String? v) {
    switch (v?.trim().toLowerCase()) {
      case 'rpg':
        return ProducerLegalType.rpg;
      case 'company':
        return ProducerLegalType.company;
      default:
        return null;
    }
  }
}

class SellerRegistrationValidator {
  SellerRegistrationValidator._();

  static const String legalLiabilityText =
      'Potvrđujem da su navedeni podaci o gazdinstvu/firmi tačni i da proizvod '
      'ispunjava zakonske sanitarne i higijenske uslove za stavljanje u promet. '
      'Kao oglašivač, snosim punu pravnu i materijalnu odgovornost za tačnost '
      'podataka i ispravnost proizvoda.';

  static final RegExp _twelveDigitsRegex = RegExp(r'^\d{12}$');
  static final RegExp _allSameTwelveDigitsRegex = RegExp(r'^(\d)\1{11}$');
  static final RegExp _nineDigitsRegex = RegExp(r'^\d{9}$');
  static final RegExp _pibFormatRegex = RegExp(r'^[1-9]\d{8}$');

  /// Uklanja razmake i crtice iz unetog broja.
  static String normalizeDigits(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'[\s\-]'), '').trim();
  }

  /// Validira BPG (Broj poljoprivrednog gazdinstva - 12 cifara).
  /// Vraća `null` ako je ispravan, ili poruku o grešci na srpskom jeziku.
  static String? validateBpg(String? rawValue) {
    final cleaned = normalizeDigits(rawValue);
    if (cleaned.isEmpty) {
      return 'Unesite BPG (Broj poljoprivrednog gazdinstva - 12 cifara).';
    }
    if (!_twelveDigitsRegex.hasMatch(cleaned)) {
      return 'BPG mora sadržati tačno 12 cifara (bez slova).';
    }
    if (_allSameTwelveDigitsRegex.hasMatch(cleaned)) {
      return 'Uneti BPG nije ispravan (sve cifre ne mogu biti iste).';
    }
    return null;
  }

  /// Validira PIB (Poreski identifikacioni broj - 9 cifara) po ISO 7064, MOD (11, 10).
  /// Vraća `null` ako je ispravan, ili poruku o grešci na srpskom jeziku.
  static String? validatePib(String? rawValue) {
    final cleaned = normalizeDigits(rawValue);
    if (cleaned.isEmpty) {
      return 'Unesite PIB (Poreski identifikacioni broj - 9 cifara).';
    }
    if (!_nineDigitsRegex.hasMatch(cleaned)) {
      return 'PIB mora sadržati tačno 9 cifara (bez slova).';
    }
    if (!_pibFormatRegex.hasMatch(cleaned)) {
      return 'PIB ne može počinjati nulom.';
    }

    int remainder = 10;
    for (int i = 0; i < 8; i++) {
      final digit = int.parse(cleaned[i]);
      remainder = (remainder + digit) % 10;
      if (remainder == 0) remainder = 10;
      remainder = (remainder * 2) % 11;
    }
    final checkDigit = (11 - remainder) % 10;
    final actualCheckDigit = int.parse(cleaned[8]);

    if (checkDigit != actualCheckDigit) {
      return 'Uneti PIB nije ispravan (nevažeća kontrolna cifra).';
    }
    return null;
  }
}

