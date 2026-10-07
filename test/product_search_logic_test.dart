import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/search_utils.dart';

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

  test('search matching parity: cackavalj and kackavalj both find Kačkavalj', () {
    const productName = 'Kozji Kačkavalj Stari';

    // Upit 'cackavalj'
    final safe1 = sanitizeProductSearchInput('cackavalj')!;
    final tokens1 = nameSearchTokens(safe1);
    expect(matchesAllSearchTokens(productName, tokens1), isTrue);

    // Upit 'kackavalj'
    final safe2 = sanitizeProductSearchInput('kackavalj')!;
    final tokens2 = nameSearchTokens(safe2);
    expect(matchesAllSearchTokens(productName, tokens2), isTrue);

    // Upit sa dijakritikom 'kačkavalj'
    final safe3 = sanitizeProductSearchInput('kačkavalj')!;
    final tokens3 = nameSearchTokens(safe3);
    expect(matchesAllSearchTokens(productName, tokens3), isTrue);
  });

  test('search matching parity: diacritics for pršuta, čvarci, đerdap', () {
    expect(matchesAllSearchTokens('Užička Pršuta', nameSearchTokens('prsuta')), isTrue);
    expect(matchesAllSearchTokens('Domaći Čvarci', nameSearchTokens('domaci cvarci')), isTrue);
    expect(matchesAllSearchTokens('Med sa Đerdapa', nameSearchTokens('djerdap')), isTrue);
    expect(matchesAllSearchTokens('Med sa Đerdapa', nameSearchTokens('derdap')), isTrue);
  });
}
