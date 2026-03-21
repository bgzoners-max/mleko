import 'package:flutter_test/flutter_test.dart';

/// Ista pravila kao u ProductsService: sanitizacija + tokeni za naziv (AND).
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

List<String> nameSearchTokens(String safe) {
  return safe
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .take(8)
      .map((t) => t.toLowerCase())
      .toList();
}

void main() {
  test('mleko does not need category match — tokens only for name filter', () {
    final safe = sanitizeProductSearchInput('mleko');
    expect(safe, 'mleko');
    expect(nameSearchTokens(safe!), ['mleko']);
  });

  test('multi-word AND', () {
    final safe = sanitizeProductSearchInput('domaći  sir');
    expect(safe, isNotNull);
    expect(nameSearchTokens(safe!), ['domaći', 'sir']);
  });
}
