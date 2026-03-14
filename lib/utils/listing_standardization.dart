class ListingStandardization {
  ListingStandardization._();

  static final RegExp _packageTokenRegex = RegExp(
    r'\b\d+([\.,]\d+)?\s?(ml|l|kg|g|kom)\b',
    caseSensitive: false,
  );

  static String? validateNameTemplate(String input) {
    final value = input.trim();
    if (value.isEmpty) {
      return 'Naziv je obavezan';
    }

    final parts =
        value.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length < 3) {
      return 'Koristi šablon: Tip proizvoda + sorta + pakovanje';
    }

    if (!_packageTokenRegex.hasMatch(value.toLowerCase())) {
      return 'Dodaj pakovanje u nazivu (npr. 720ml, 1kg, 10kom)';
    }

    return null;
  }

  static bool hasPackageToken(String input) {
    return _packageTokenRegex.hasMatch(input.toLowerCase());
  }

  static String normalizeKey(String input) {
    final lower = input.trim().toLowerCase();
    if (lower.isEmpty) {
      return '';
    }

    final withoutDiacritics = _replaceDiacritics(lower);
    final onlyAlphaNum =
        withoutDiacritics.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    return onlyAlphaNum.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _replaceDiacritics(String input) {
    return input
        .replaceAll('č', 'c')
        .replaceAll('ć', 'c')
        .replaceAll('š', 's')
        .replaceAll('ž', 'z')
        .replaceAll('đ', 'dj');
  }
}
