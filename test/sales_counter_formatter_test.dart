import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/sales_counter_formatter.dart';

void main() {
  group('formatSalesTier', () {
    test('returns null for null, 0, or count < 10', () {
      expect(formatSalesTier(null), isNull);
      expect(formatSalesTier(0), isNull);
      expect(formatSalesTier(1), isNull);
      expect(formatSalesTier(5), isNull);
      expect(formatSalesTier(9), isNull);
    });

    test('correctly maps 10..24 to 10+', () {
      expect(formatSalesTier(10), equals('10+'));
      expect(formatSalesTier(15), equals('10+'));
      expect(formatSalesTier(24), equals('10+'));
    });

    test('correctly maps 25..49 to 25+', () {
      expect(formatSalesTier(25), equals('25+'));
      expect(formatSalesTier(30), equals('25+'));
      expect(formatSalesTier(49), equals('25+'));
    });

    test('correctly maps 50..99 to 50+', () {
      expect(formatSalesTier(50), equals('50+'));
      expect(formatSalesTier(75), equals('50+'));
      expect(formatSalesTier(99), equals('50+'));
    });

    test('correctly maps 100..249 to 100+', () {
      expect(formatSalesTier(100), equals('100+'));
      expect(formatSalesTier(199), equals('100+'));
      expect(formatSalesTier(249), equals('100+'));
    });

    test('correctly maps 250..499 to 250+', () {
      expect(formatSalesTier(250), equals('250+'));
      expect(formatSalesTier(350), equals('250+'));
      expect(formatSalesTier(499), equals('250+'));
    });

    test('correctly maps 500..999 to 500+', () {
      expect(formatSalesTier(500), equals('500+'));
      expect(formatSalesTier(750), equals('500+'));
      expect(formatSalesTier(999), equals('500+'));
    });

    test('correctly maps 1000..4999 to 1k+ or 1.000+', () {
      expect(formatSalesTier(1000, useKNotation: true), equals('1k+'));
      expect(formatSalesTier(1000, useKNotation: false), equals('1.000+'));
      expect(formatSalesTier(4999, useKNotation: true), equals('1k+'));
      expect(formatSalesTier(4999, useKNotation: false), equals('1.000+'));
    });

    test('correctly maps 5000..9999 to 5k+ or 5.000+', () {
      expect(formatSalesTier(5000, useKNotation: true), equals('5k+'));
      expect(formatSalesTier(5000, useKNotation: false), equals('5.000+'));
      expect(formatSalesTier(9999, useKNotation: true), equals('5k+'));
    });

    test('correctly maps 10000+ to 10k+ or 10.000+', () {
      expect(formatSalesTier(10000, useKNotation: true), equals('10k+'));
      expect(formatSalesTier(10000, useKNotation: false), equals('10.000+'));
      expect(formatSalesTier(50000, useKNotation: true), equals('10k+'));
    });
  });

  group('formatSalesCount', () {
    test('returns null for count < 10', () {
      expect(formatSalesCount(null), isNull);
      expect(formatSalesCount(0), isNull);
      expect(formatSalesCount(7), isNull);
    });

    test('appends default suffix "prodaja"', () {
      expect(formatSalesCount(12), equals('10+ prodaja'));
      expect(formatSalesCount(35), equals('25+ prodaja'));
      expect(formatSalesCount(55), equals('50+ prodaja'));
      expect(formatSalesCount(150), equals('100+ prodaja'));
      expect(formatSalesCount(300), equals('250+ prodaja'));
      expect(formatSalesCount(600), equals('500+ prodaja'));
      expect(formatSalesCount(1200), equals('1k+ prodaja'));
      expect(formatSalesCount(5500), equals('5k+ prodaja'));
      expect(formatSalesCount(12000), equals('10k+ prodaja'));
    });

    test('supports custom or empty suffix', () {
      expect(formatSalesCount(15, suffix: 'prodatih komada'), equals('10+ prodatih komada'));
      expect(formatSalesCount(15, suffix: null), equals('10+'));
      expect(formatSalesCount(15, suffix: ''), equals('10+'));
      expect(formatSalesCount(15, suffix: '   '), equals('10+'));
    });

    test('respects useKNotation = false for thousands', () {
      expect(formatSalesCount(1200, useKNotation: false), equals('1.000+ prodaja'));
      expect(formatSalesCount(5500, useKNotation: false), equals('5.000+ prodaja'));
      expect(formatSalesCount(12000, useKNotation: false), equals('10.000+ prodaja'));
    });
  });

  group('formatSalesBadge', () {
    test('returns uppercase badge text for >= 10 and null for < 10', () {
      expect(formatSalesBadge(3), isNull);
      expect(formatSalesBadge(10), equals('10+ PRODAJA'));
      expect(formatSalesBadge(50), equals('50+ PRODAJA'));
      expect(formatSalesBadge(100), equals('100+ PRODAJA'));
      expect(formatSalesBadge(1500), equals('1K+ PRODAJA'));
      expect(formatSalesBadge(1500, useKNotation: false), equals('1.000+ PRODAJA'));
    });
  });
}
