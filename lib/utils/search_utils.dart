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
