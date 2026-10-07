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

    test('latinizeSearchText converts Serbian diacritics to Latin ASCII', () {
      expect(latinizeSearchText('Kačkavalj'), 'kackavalj');
      expect(latinizeSearchText('Čokolada'), 'cokolada');
      expect(latinizeSearchText('Pršuta'), 'prsuta');
      expect(latinizeSearchText('Žitarice'), 'zitarice');
      expect(latinizeSearchText('Đerdap'), 'djerdap');
      expect(latinizeSearchText('Domaći Sir'), 'domaci sir');
    });

    test('stripDiacritics normalizes dj and d for loose matching', () {
      expect(stripDiacritics('Đerdap'), 'derdap');
      expect(stripDiacritics('Djerdap'), 'derdap');
      expect(stripDiacritics('Kačkavalj'), 'kackavalj');
    });

    test('matchesSearchToken handles diacritics and cackavalj -> kačkavalj typo', () {
      // Dijakritici: kackavalj nalazi Kačkavalj
      expect(matchesSearchToken('Kačkavalj pirotski', 'kackavalj'), isTrue);
      expect(matchesSearchToken('Pirotski kačkavalj', 'kackavalj'), isTrue);
      expect(matchesSearchToken('Kačkavalj', 'kačkavalj'), isTrue);

      // cackavalj nalazi kačkavalj (fonetski / c umesto k i č)
      expect(matchesSearchToken('Kačkavalj stari', 'cackavalj'), isTrue);

      // Pršuta, čvarci, domaći
      expect(matchesSearchToken('Zlatiborska pršuta', 'prsuta'), isTrue);
      expect(matchesSearchToken('Domaći duvan čvarci', 'cvarci'), isTrue);
      expect(matchesSearchToken('Domaće kiselo mleko', 'domace'), isTrue);

      // Đerdap: sa dj ili d
      expect(matchesSearchToken('Kozji sir Đerdap', 'djerdap'), isTrue);
      expect(matchesSearchToken('Kozji sir Đerdap', 'derdap'), isTrue);
      expect(matchesSearchToken('Kozji sir Đerdap', 'đerdap'), isTrue);

      // Negativni slučajevi (ne sme lažno da spaja nepovezane reči)
      expect(matchesSearchToken('Sveže jagode', 'jabuke'), isFalse);
      expect(matchesSearchToken('Kravlji sir', 'med'), isFalse);
    });

    test('matchesAllSearchTokens enforces AND matching', () {
      final tokens = ['domaci', 'kackavalj'];
      expect(matchesAllSearchTokens('Domaći stari kačkavalj', tokens), isTrue);
      expect(matchesAllSearchTokens('Domaći mladi sir', tokens), isFalse);
    });
  });
}
