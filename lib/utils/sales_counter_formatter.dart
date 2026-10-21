/// Pomoćne funkcije za formatiranje broja prodaja / kupovina prema pragovima (Social Proof).
///
/// Prema ugovorenoj specifikaciji:
/// - Za manje od 10 prodaja (ili null) se ne prikazuje ništa (vraća `null`) kako bi se
///   izbegao negativan utisak kod kupaca ("cold start").
/// - Za 10 i više prodaja prikazuju se pragovi:
///   10+, 25+, 50+, 100+, 250+, 500+, 1.000+ (ili 1k+), 5k+, 10k+.
library;

/// Vraća oznaku praga za dati broj prodaja bez pratećeg teksta (npr. '10+', '50+', '1k+').
/// Vraća `null` ako je [count] manji od 10 ili null.
String? formatSalesTier(int? count, {bool useKNotation = true}) {
  if (count == null || count < 10) return null;

  if (count < 25) {
    return '10+';
  } else if (count < 50) {
    return '25+';
  } else if (count < 100) {
    return '50+';
  } else if (count < 250) {
    return '100+';
  } else if (count < 500) {
    return '250+';
  } else if (count < 1000) {
    return '500+';
  } else if (count < 5000) {
    return useKNotation ? '1k+' : '1.000+';
  } else if (count < 10000) {
    return useKNotation ? '5k+' : '5.000+';
  } else {
    return useKNotation ? '10k+' : '10.000+';
  }
}

/// Formatira broj prodaja sa sufiksom (podrazumevano 'prodaja').
///
/// Primeri:
/// - count = 3   -> null (sakriva se)
/// - count = 14  -> '10+ prodaja'
/// - count = 35  -> '25+ prodaja'
/// - count = 80  -> '50+ prodaja'
/// - count = 120 -> '100+ prodaja'
/// - count = 300 -> '250+ prodaja'
/// - count = 750 -> '500+ prodaja'
/// - count = 1500 -> '1k+ prodaja' (ili '1.000+ prodaja' ako je useKNotation = false)
/// - count = 6000 -> '5k+ prodaja'
/// - count = 15000 -> '10k+ prodaja'
String? formatSalesCount(
  int? count, {
  String? suffix = 'prodaja',
  bool useKNotation = true,
}) {
  final tier = formatSalesTier(count, useKNotation: useKNotation);
  if (tier == null) return null;

  if (suffix == null || suffix.trim().isEmpty) {
    return tier;
  }
  return '$tier ${suffix.trim()}';
}

/// Formatira tekst za bedž na kartici proizvoda (npr. '10+ PRODAJA', '50+ PRODAJA').
String? formatSalesBadge(int? count, {bool useKNotation = true}) {
  final formatted = formatSalesCount(count, suffix: 'prodaja', useKNotation: useKNotation);
  return formatted?.toUpperCase();
}
