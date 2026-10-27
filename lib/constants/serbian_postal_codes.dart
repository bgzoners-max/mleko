import 'serbian_postal_codes_data_1.dart';
import 'serbian_postal_codes_data_2.dart';
import 'serbian_postal_codes_data_3.dart';
import 'serbian_postal_codes_data_4.dart';

/// Model za poštanski broj, mesto i opciono naselje/selo u Srbiji.
class PostalCodeEntry {
  final String code;
  final String city;
  final String settlement;
  final bool isPrimary;

  const PostalCodeEntry({
    required this.code,
    required this.city,
    this.settlement = '',
    this.isPrimary = true,
  });

  @override
  String toString() => '$code $city';
}

/// Centralizovani spisak svih 2043 poštanskih brojeva, mesta i sela u Srbiji.
/// Pruža instant autocomplete predloge i dvosmernu sinhronizaciju (poštanski broj <-> grad).
class SerbianPostalCodes {
  SerbianPostalCodes._();

  /// Spisak svih poštanskih unosa u Srbiji.
  static const List<PostalCodeEntry> all = [
    ...serbianPostalCodesPart1,
    ...serbianPostalCodesPart2,
    ...serbianPostalCodesPart3,
    ...serbianPostalCodesPart4,
  ];

  static final Map<String, String> _byCode = {
    for (final entry in all)
      if (entry.isPrimary) entry.code: entry.city,
  };

  /// Pronalazi matično mesto na osnovu tačnog poštanskog broja.
  static String? cityForCode(String code) {
    return _byCode[code.trim()];
  }

  /// Pronalazi poštanski broj za dati grad ili naselje.
  static String? codeForCity(String city) {
    final clean = _stripDiacritics(city.trim().toLowerCase());
    if (clean.isEmpty) return null;
    for (final entry in all) {
      if (_stripDiacritics(entry.city.toLowerCase()) == clean ||
          (entry.settlement.isNotEmpty && _stripDiacritics(entry.settlement.toLowerCase()) == clean)) {
        return entry.code;
      }
    }
    return null;
  }

  /// Vraća predloge na osnovu upita (cifre poštanskog broja, naziv grada ili naziv sela/naselja).
  /// Tolerantno na kvačice i velika/mala slova.
  static List<PostalCodeEntry> suggestions(String query, {int limit = 15}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final isNumeric = RegExp(r'^[0-9]+$').hasMatch(trimmed);
    final cleanQuery = _stripDiacritics(trimmed.toLowerCase());

    final results = <PostalCodeEntry>[];
    for (final entry in all) {
      bool matches = false;
      if (isNumeric) {
        matches = entry.code.startsWith(trimmed);
      } else {
        final cleanCity = _stripDiacritics(entry.city.toLowerCase());
        matches = cleanCity.contains(cleanQuery) ||
            (entry.settlement.isNotEmpty && _stripDiacritics(entry.settlement.toLowerCase()).contains(cleanQuery)) ||
            entry.code.startsWith(trimmed);
      }

      if (matches) {
        results.add(entry);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  static String _stripDiacritics(String text) {
    return text
        .replaceAll('č', 'c')
        .replaceAll('ć', 'c')
        .replaceAll('đ', 'dj')
        .replaceAll('š', 's')
        .replaceAll('ž', 'z')
        .replaceAll('Č', 'C')
        .replaceAll('Ć', 'C')
        .replaceAll('Đ', 'Dj')
        .replaceAll('Š', 'S')
        .replaceAll('Ž', 'Z');
  }
}

