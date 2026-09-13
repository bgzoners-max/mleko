import 'dart:math' as math;

/// Pomoćne funkcije za robusno parsiranje numeričkih unosa korisnika
/// (podržava srpske i internacionalne formate separatora hiljada i decimala).
class NumberInputUtils {
  const NumberInputUtils._();

  /// Parsira unos broja u [double].
  ///
  /// Podržava:
  /// - Separator hiljada sa tačkom: "1.500" -> 1500.0, "185.000" -> 185000.0
  /// - Decimalni zarez ili tačku: "1,5" -> 1.5, "1.5" -> 1.5, "0,75" -> 0.75
  /// - Kombinovane formate: "1.500,50" -> 1500.50, "1,500.50" -> 1500.50
  /// - Višestruke separatore: "1.250.000" -> 1250000.0
  ///
  /// Ako je [allowThousands] uključeno (podrazumevano), pojedinačna tačka praćena sa
  /// tačno 3 cifre na kraju (npr. "1.500", "25.000") tretira se kao separator hiljada,
  /// osim ako ceo broj već ima decimalni zarez (npr. "1.500,25").
  static double? parseDecimal(
    String? raw, {
    int maxDecimals = 2,
    bool allowThousands = true,
  }) {
    if (raw == null) return null;
    var str = raw.trim();
    if (str.isEmpty) return null;

    // Normalizacija razmaka (npr. non-breaking space "1 500")
    str = str.replaceAll(RegExp(r'[\s\u00A0\u202F]'), '');
    if (str.isEmpty) return null;

    // Proveri da li postoje oba separatora (. i ,)
    final hasDot = str.contains('.');
    final hasComma = str.contains(',');

    if (hasDot && hasComma) {
      final lastDot = str.lastIndexOf('.');
      final lastComma = str.lastIndexOf(',');

      if (lastComma > lastDot) {
        // Evropski / Srpski format: 1.500,50 (tačka je hiljada, zarez je decimala)
        str = str.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Anglosaksonski format: 1,500.50 (zarez je hiljada, tačka je decimala)
        str = str.replaceAll(',', '');
      }
    } else if (hasDot && !hasComma) {
      final dotCount = '.'.allMatches(str).length;
      if (dotCount > 1) {
        // Više tačaka (npr. 1.250.000) -> separatori hiljada ako su grupisani u trojke
        if (!RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(str)) {
          return null;
        }
        str = str.replaceAll('.', '');
      } else if (allowThousands) {
        // Jedna tačka: ako iza nje ima tačno 3 cifre i to je kraj stringa
        // (npr. 1.500 ili 185.000), u našem kontekstu (cene, kilometraža) to je separator hiljada.
        final match = RegExp(r'^(\d+)\.(\d{3})$').firstMatch(str);
        if (match != null) {
          str = match.group(1)! + match.group(2)!;
        }
      }
    } else if (hasComma && !hasDot) {
      final commaCount = ','.allMatches(str).length;
      if (commaCount > 1) {
        // Više zareza (npr. 1,250,000) -> separatori hiljada ako su grupisani u trojke
        if (!RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(str)) {
          return null;
        }
        str = str.replaceAll(',', '');
      } else {
        // Jedan zarez: u srpskom jeziku zarez je decimalni separator ("1,5", "0,75")
        str = str.replaceAll(',', '.');
      }
    }

    final parsed = double.tryParse(str);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;

    if (maxDecimals >= 0) {
      final factor = math.pow(10, maxDecimals);
      return (parsed * factor).round() / factor;
    }

    return parsed;
  }

  /// Parsira unos u celi broj [int], uklanjajući separatore hiljada.
  static int? parseInteger(String? raw) {
    final d = parseDecimal(raw, maxDecimals: 0, allowThousands: true);
    return d?.toInt();
  }
}

/// Top-level pomoćna funkcija za parsiranje decimalnih unosa.
double? parseDecimal(
  String? raw, {
  int maxDecimals = 2,
  bool allowThousands = true,
}) =>
    NumberInputUtils.parseDecimal(
      raw,
      maxDecimals: maxDecimals,
      allowThousands: allowThousands,
    );

/// Top-level pomoćna funkcija za parsiranje celobrojnih unosa.
int? parseInteger(String? raw) => NumberInputUtils.parseInteger(raw);

