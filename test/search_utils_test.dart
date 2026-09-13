import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/search_utils.dart';

void main() {
  group('SearchUtils', () {
    test('sanitizeProductSearchInput cleans and limits inputs', () {
      expect(sanitizeProductSearchInput(null), isNull);
      expect(sanitizeProductSearchInput('   '), isNull);
      expect(sanitizeProductSearchInput('***%%%___'), isNull);

      // Uklanja specijalne SQL/regex karaktere, zadržava dijakritike i normalizuje razmake
      expect(sanitizeProductSearchInput('  Domaći* %sir_ sa   Zlatibora!  '), 'Domaći sir sa Zlatibora');

      // Seče na 50 karaktera
      const longInput = 'Ovo je izuzetno dugačak tekst pretrage koji prelazi maksimalno dozvoljenih pedeset karaktera';
      final sanitized = sanitizeProductSearchInput(longInput);
      expect(sanitized, isNotNull);
      expect(sanitized!.length, lessThanOrEqualTo(50));
    });

    test('nameSearchTokens splits into lowercase tokens with maximum limit', () {
      final tokens = nameSearchTokens('Kozji Kačkavalj Dimljeni Stari Pirotski');
      expect(tokens, ['kozji', 'kačkavalj', 'dimljeni', 'stari', 'pirotski']);

      // Ograničava na kMaxSearchTokens (8)
      final manyTokens = nameSearchTokens('1 2 3 4 5 6 7 8 9 10 11');
      expect(manyTokens.length, 8);
    });
  });
}
