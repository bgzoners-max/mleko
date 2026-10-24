/// Pomoćne funkcije za formatiranje i parsiranje cena, količina i mernih jedinica.
///
/// Izdvojeno iz [ProductModel] radi modularnosti i SRP (Single Responsibility Principle).
class ProductFormattingUtils {
  /// Oznaka valute za prikaz — domaći ton ("din.").
  static const String priceCurrencyLabel = 'din.';

  /// Srpska konvencija decimala: zarez umesto tačke ("1,5" umesto "1.5").
  static String formatDecimal(double value) {
    if (!value.isFinite) return '0';
    if (value.truncateToDouble() == value) {
      return value.toInt().toString();
    }
    var str = value.toStringAsFixed(3);
    str = str.replaceFirst(RegExp(r'0+$'), '');
    str = str.replaceFirst(RegExp(r'\.$'), '');
    return str.replaceAll('.', ',');
  }

  /// Srpska gramatička pravila za množinu na osnovu broja (Slavic plural).
  static String pluralSr(
    num count, {
    required String one,
    required String few,
    required String many,
  }) {
    final int n = count.abs().round();
    final int mod10 = n % 10;
    final int mod100 = n % 100;

    if (mod100 >= 11 && mod100 <= 14) {
      return many;
    }
    if (mod10 == 1) {
      return one;
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return few;
    }
    return many;
  }

  /// Formatira količinu za prikaz sa mernom jedinicom.
  static String formatQuantityWithUnit(double value, String unitType) {
    if (unitType == 'L') {
      if (value < 1 && value > 0) return '${(value * 1000).round()} ml';
      return '${formatDecimal(value)} L';
    }
    if (unitType == 'g') {
      final grams = (value * 1000).round();
      return '$grams g';
    }
    if (unitType == 'kom') {
      return '${formatDecimal(value)} kom';
    }
    if (unitType == 'veza') {
      final suffix = pluralSr(value, one: 'veza', few: 'veze', many: 'veza');
      return '${formatDecimal(value)} $suffix';
    }
    if (unitType == 'pak') {
      final suffix =
          pluralSr(value, one: 'pakovanje', few: 'pakovanja', many: 'pakovanja');
      return '${formatDecimal(value)} $suffix';
    }
    if (value < 1 && value > 0) {
      final grams = (value * 1000).round();
      return '$grams g';
    }
    return '${formatDecimal(value)} kg';
  }

  /// Parsira unos količine za kilograme (npr. "0.1", "100g", "1.5 kg").
  static double parseQuantityKg(String text) {
    var raw = text.trim().toLowerCase();
    if (raw.isEmpty) return 0;

    final isGrams = (raw.endsWith('grama') ||
            raw.endsWith('gram') ||
            raw.endsWith('gr') ||
            raw.endsWith('g')) &&
        !raw.contains('kg');

    if (isGrams) {
      final numPart = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
      final v = double.tryParse(numPart.replaceAll(',', '.'));
      if (v != null && v > 0) return v / 1000.0;
    }

    raw = raw.replaceAll('kg', '').replaceAll(',', '.').trim();
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return 0;

    return v;
  }

  /// Parsira unos količine za litre (npr. "750 ml", "0.75", "1.5 L").
  static double parseQuantityL(String text) {
    var raw = text.trim().toLowerCase();
    if (raw.isEmpty) return 0;

    final isMl = raw.endsWith('ml') ||
        raw.endsWith('mili') ||
        raw.endsWith('mililitara') ||
        raw.endsWith('mililitra');
    if (isMl) {
      final numPart = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
      final v = double.tryParse(numPart.replaceAll(',', '.'));
      if (v != null && v > 0) return v / 1000.0;
    }

    raw = raw
        .replaceAll('litara', '')
        .replaceAll('litra', '')
        .replaceAll('litar', '')
        .replaceAll('l', '')
        .replaceAll(',', '.')
        .trim();
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return 0;
    if (v >= 100) return v / 1000.0;

    return v;
  }

  /// Parsira unos količine za grame (npr. "100", "250").
  static double parseQuantityG(String text) {
    final v = double.tryParse(text.replaceAll(',', '.').trim());
    if (v == null) return 0;
    return v / 1000;
  }
}
