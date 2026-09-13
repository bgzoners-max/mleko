import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/number_input_utils.dart';

void main() {
  group('NumberInputUtils.parseDecimal', () {
    test('parses basic numbers correctly', () {
      expect(NumberInputUtils.parseDecimal('100'), equals(100.0));
      expect(NumberInputUtils.parseDecimal('0'), equals(0.0));
      expect(NumberInputUtils.parseDecimal('12.5'), equals(12.5));
      expect(NumberInputUtils.parseDecimal('12,5'), equals(12.5));
      expect(NumberInputUtils.parseDecimal('0.75'), equals(0.75));
      expect(NumberInputUtils.parseDecimal('0,75'), equals(0.75));
      expect(NumberInputUtils.parseDecimal('.5'), equals(0.5));
      expect(NumberInputUtils.parseDecimal(',5'), equals(0.5));
      expect(NumberInputUtils.parseDecimal('50.'), equals(50.0));
      expect(NumberInputUtils.parseDecimal('50,'), equals(50.0));
    });

    test('parses thousand separators in prices and mileage', () {
      // 1.500 RSD cena ili 1.500 km
      expect(NumberInputUtils.parseDecimal('1.500'), equals(1500.0));
      expect(NumberInputUtils.parseDecimal('185.000'), equals(185000.0));
      expect(NumberInputUtils.parseDecimal('2.500.000'), equals(2500000.0));
      expect(NumberInputUtils.parseDecimal('1 500'), equals(1500.0));
    });

    test('respects allowThousands: false for quantities and measurements', () {
      // Kada allowThousands nije dozvoljeno (npr. količine sira u kg), 1.500 je 1.5 kg
      expect(
        NumberInputUtils.parseDecimal('1.500', allowThousands: false),
        equals(1.5),
      );
      expect(
        NumberInputUtils.parseDecimal('0.500', allowThousands: false),
        equals(0.5),
      );
    });

    test('supports unicode spaces (non-breaking and narrow NBSP)', () {
      expect(NumberInputUtils.parseDecimal('1\u00A0500'), equals(1500.0));
      expect(NumberInputUtils.parseDecimal('2\u202F500,50'), equals(2500.5));
    });

    test('parses combined thousand and decimal separators', () {
      // Evropski/srpski: 1.500,50
      expect(NumberInputUtils.parseDecimal('1.500,50'), equals(1500.5));
      expect(NumberInputUtils.parseDecimal('185.000,25'), equals(185000.25));

      // Anglosaksonski: 1,500.50
      expect(NumberInputUtils.parseDecimal('1,500.50'), equals(1500.5));

      // Više zareza (anglosaksonske hiljade: 1,250,000)
      expect(NumberInputUtils.parseDecimal('1,250,000'), equals(1250000.0));
    });

    test('handles whitespace and empty strings gracefully', () {
      expect(NumberInputUtils.parseDecimal(null), isNull);
      expect(NumberInputUtils.parseDecimal(''), isNull);
      expect(NumberInputUtils.parseDecimal('   '), isNull);
      expect(NumberInputUtils.parseDecimal('abc'), isNull);
      expect(NumberInputUtils.parseDecimal('1.2.3.4'), isNull);
    });

    test('clamps to maxDecimals properly', () {
      expect(NumberInputUtils.parseDecimal('12.3456', maxDecimals: 2), equals(12.35));
      expect(NumberInputUtils.parseDecimal('12,3456', maxDecimals: 2), equals(12.35));
      expect(NumberInputUtils.parseDecimal('12.3456', maxDecimals: 0), equals(12.0));
      expect(NumberInputUtils.parseDecimal('12.3456', maxDecimals: -1), equals(12.3456));
    });

    test('bug #5 price formatting scenarios: single dot followed by 3 digits treated as thousands', () {
      // Korisnik unosi cenu "1.234" EUR/RSD -> to je 1234, a ne 1.23
      expect(NumberInputUtils.parseDecimal('1.234'), equals(1234.0));
      expect(NumberInputUtils.parseDecimal('1.234', maxDecimals: 2), equals(1234.0));
      // Ako unese sa zarezom "1234,56", zaokružuje se na 2 decimale
      expect(NumberInputUtils.parseDecimal('1234,567', maxDecimals: 2), equals(1234.57));
    });
  });

  group('NumberInputUtils.parseInteger', () {
    test('parses integers with thousand separators', () {
      expect(NumberInputUtils.parseInteger('1.500'), equals(1500));
      expect(NumberInputUtils.parseInteger('185.000'), equals(185000));
      expect(NumberInputUtils.parseInteger('250'), equals(250));
      expect(NumberInputUtils.parseInteger('  1.200  '), equals(1200));
      expect(NumberInputUtils.parseInteger(null), isNull);
      expect(NumberInputUtils.parseInteger(''), isNull);
      expect(NumberInputUtils.parseInteger('invalid'), isNull);
    });
  });

  group('Top-level parseDecimal and parseInteger functions', () {
    test('top-level parseDecimal delegates correctly', () {
      expect(parseDecimal('100.50'), equals(100.5));
      expect(parseDecimal('1.500'), equals(1500.0));
      expect(parseDecimal('1.500', allowThousands: false), equals(1.5));
      expect(parseDecimal(null), isNull);
    });

    test('top-level parseInteger delegates correctly', () {
      expect(parseInteger('1.500'), equals(1500));
      expect(parseInteger('42'), equals(42));
      expect(parseInteger(null), isNull);
    });
  });
}
