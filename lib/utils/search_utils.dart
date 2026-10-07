/// Veličina jedne stranice pri paginaciji
const int productsPageSize = 20;

/// Maksimalan broj reči u upitu (AND pretraga po nazivu).
const int kMaxSearchTokens = 8;

/// Čisti tekstualni upit; vraća `null` ako nema smislenog sadržaja.
String? sanitizeProductSearchInput(String? searchQuery) {
  if (searchQuery == null) return null;
  final trimmed = searchQuery.trim();
  if (trimmed.isEmpty) return null;
  final limited = trimmed.length > 50 ? trimmed.substring(0, 50) : trimmed;
  final safe = limited
      .replaceAll(RegExp(r'[*%_]'), '')
      .replaceAll(
        RegExp(r'[^\p{L}\p{N}\s\-_.]+', unicode: true),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return safe.isEmpty ? null : safe;
}

/// Tokeni za pretragu — samo naziv proizvoda; sve reči moraju biti podstring naziva (AND).
List<String> nameSearchTokens(String safe) {
  return safe
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .take(kMaxSearchTokens)
      .map((t) => t.toLowerCase())
      .toList();
}

/// Normalizuje tekst pretrage konverzijom srpskih dijakritika u ASCII ekvivalente
/// (č/ć -> c, š -> s, ž -> z, đ -> dj).
String latinizeSearchText(String input) {
  return input
      .toLowerCase()
      .replaceAll('č', 'c')
      .replaceAll('ć', 'c')
      .replaceAll('š', 's')
      .replaceAll('ž', 'z')
      .replaceAll('đ', 'dj');
}

/// Dodatna normalizacija gde se i `đ` i `dj` svode na `d`
/// za toleranciju kucanja bez j ('derdap' vs 'đerdap').
String stripDiacritics(String input) {
  return input
      .toLowerCase()
      .replaceAll('č', 'c')
      .replaceAll('ć', 'c')
      .replaceAll('š', 's')
      .replaceAll('ž', 'z')
      .replaceAll('đ', 'd')
      .replaceAll('dj', 'd');
}

/// Računa Levenshtein distancu između dva stringa.
int levenshteinDistance(String s1, String s2) {
  if (s1 == s2) return 0;
  if (s1.isEmpty) return s2.length;
  if (s2.isEmpty) return s1.length;

  final List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
  final List<int> v1 = List<int>.filled(s2.length + 1, 0);

  for (int i = 0; i < s1.length; i++) {
    v1[0] = i + 1;
    for (int j = 0; j < s2.length; j++) {
      final cost = s1[i] == s2[j] ? 0 : 1;
      v1[j + 1] = [
        v1[j] + 1,
        v0[j + 1] + 1,
        v0[j] + cost,
      ].reduce((min, val) => val < min ? val : min);
    }
    for (int j = 0; j <= s2.length; j++) {
      v0[j] = v1[j];
    }
  }

  return v1[s2.length];
}

/// Računa sličnost na osnovu trigrama (0.0 do 1.0).
double trigramSimilarity(String s1, String s2) {
  if (s1 == s2) return 1.0;
  if (s1.isEmpty || s2.isEmpty) return 0.0;

  Set<String> getTrigrams(String s) {
    final padded = '  $s ';
    final trigrams = <String>{};
    for (int i = 0; i < padded.length - 2; i++) {
      trigrams.add(padded.substring(i, i + 3));
    }
    return trigrams;
  }

  final t1 = getTrigrams(s1);
  final t2 = getTrigrams(s2);
  final intersection = t1.intersection(t2).length;
  final union = t1.union(t2).length;
  if (union == 0) return 0.0;
  return intersection / union;
}

/// Proverava da li tekst kandidata odgovara datom search tokenu,
/// uzimajući u obzir dijakritike i fuzzy toleranciju za tipfelere (npr. cackavalj -> kačkavalj).
bool matchesSearchToken(String candidateText, String token) {
  final normText = latinizeSearchText(candidateText);
  final normToken = latinizeSearchText(token);

  if (normText.contains(normToken)) return true;

  final strippedText = stripDiacritics(candidateText);
  final strippedToken = stripDiacritics(token);
  if (strippedText.contains(strippedToken)) return true;

  // Reč po reč poređenje (npr. 'cackavalj' vs 'kackavalj' u 'kozji kackavalj')
  final words = normText.split(RegExp(r'\s+'));
  for (final word in words) {
    if (word.isEmpty) continue;
    if (word.contains(normToken) || normToken.contains(word)) return true;

    // Za reči od barem 4 karaktera, dozvoli 1 tipfeler (npr. cackavalj vs kackavalj)
    if (normToken.length >= 4 && (word.length - normToken.length).abs() <= 2) {
      final dist = levenshteinDistance(word, normToken);
      if (dist <= 1) return true;
      if (normToken.length >= 7 && dist <= 2) return true;
      if (trigramSimilarity(word, normToken) >= 0.35) return true;
    }
  }

  return false;
}

/// Proverava da li tekst kandidata zadovoljava sve tokene (AND logika).
bool matchesAllSearchTokens(String candidateText, List<String> tokens) {
  if (tokens.isEmpty) return true;
  return tokens.every((token) => matchesSearchToken(candidateText, token));
}
