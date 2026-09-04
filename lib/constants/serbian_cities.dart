/// Centralizovana lista gradova i normalizacija unosa lokacija u oglasima.
class SerbianCities {
  SerbianCities._();

  /// Glavna lista najčešćih gradova i većih opština u Srbiji (sortirana po abecedi).
  static const List<String> all = [
    'Aleksinac',
    'Aranđelovac',
    'Bačka Palanka',
    'Beograd',
    'Bor',
    'Čačak',
    'Ćuprija',
    'Gornji Milanovac',
    'Inđija',
    'Jagodina',
    'Kikinda',
    'Kopaonik',
    'Kragujevac',
    'Kraljevo',
    'Kruševac',
    'Leskovac',
    'Loznica',
    'Mladenovac',
    'Negotin',
    'Niš',
    'Novi Pazar',
    'Novi Sad',
    'Obrenovac',
    'Pančevo',
    'Paraćin',
    'Pirot',
    'Požarevac',
    'Priboj',
    'Prijepolje',
    'Prokuplje',
    'Raška',
    'Ruma',
    'Šabac',
    'Sjenica',
    'Smederevo',
    'Sombor',
    'Sremska Mitrovica',
    'Subotica',
    'Trstenik',
    'Užice',
    'Valjevo',
    'Vranje',
    'Vrbas',
    'Vršac',
    'Zaječar',
    'Zlatibor',
    'Zrenjanin',
  ];

  /// Vraća listu gradova filtriranu po upitu (case-insensitive i diacritic-tolerant).
  static List<String> suggestions(String query) {
    final cleanQuery = _stripDiacritics(query.trim().toLowerCase());
    if (cleanQuery.isEmpty) return all;

    return all.where((city) {
      final cleanCity = _stripDiacritics(city.toLowerCase());
      return cleanCity.contains(cleanQuery);
    }).toList();
  }

  /// Normalizuje unos grada:
  /// 1. Uklanja višak razmaka.
  /// 2. Proverava da li odgovara nekom od poznatih gradova (tolerantno na kvačice i velika/mala slova).
  /// 3. Ako je u pitanju drugo mesto, primenjuje Title Case (svaka reč počinje velikim slovom).
  static String normalize(String rawCity) {
    final trimmed = rawCity.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return '';

    final cleanInput = _stripDiacritics(trimmed.toLowerCase());

    for (final city in all) {
      if (_stripDiacritics(city.toLowerCase()) == cleanInput) {
        return city;
      }
    }

    // Ako nije na listi glavnih gradova, primeni Title Case (npr. "bela crkva" -> "Bela Crkva")
    return trimmed.split(' ').map((word) {
      if (word.isEmpty) return '';
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
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
