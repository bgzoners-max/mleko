import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/jar_standards.dart';

void main() {
  group('JarStandards', () {
    test('isHoneyLike prepoznaje sinonime za med', () {
      expect(JarStandards.isHoneyLike('Med'), isTrue);
      expect(JarStandards.isHoneyLike('Bagremov med'), isTrue);
      expect(JarStandards.isHoneyLike('medljika'), isTrue);
      expect(JarStandards.isHoneyLike('honey'), isTrue);
      expect(JarStandards.isHoneyLike('Sir'), isFalse);
      expect(JarStandards.isHoneyLike('Ajvar'), isFalse);
    });

    test('litersFromMl pretvara mililitre u litre', () {
      expect(JarStandards.litersFromMl(720), closeTo(0.72, 0.0001));
      expect(JarStandards.litersFromMl(1000), closeTo(1.0, 0.0001));
      expect(JarStandards.litersFromMl(0), closeTo(0.0, 0.0001));
    });

    test('honeyKgFromMl skalira na referentnih 720 ml = 1 kg', () {
      expect(JarStandards.honeyKgFromMl(720), closeTo(1.0, 0.0001));
      expect(JarStandards.honeyKgFromMl(360), closeTo(0.5, 0.0001));
      expect(JarStandards.honeyKgFromMl(1440), closeTo(2.0, 0.0001));
    });

    test('genericNetRangeKgFromMl daje 700-900 g po 720 ml', () {
      final range = JarStandards.genericNetRangeKgFromMl(720);
      expect(range.minKg, closeTo(0.7, 0.0001));
      expect(range.maxKg, closeTo(0.9, 0.0001));
    });

    test('formatKg formatira cele kilograme, kilograme i grame', () {
      expect(JarStandards.formatKg(1), '1 kg');
      expect(JarStandards.formatKg(2), '2 kg');
      expect(JarStandards.formatKg(1.5), '1.50 kg');
      expect(JarStandards.formatKg(0.5), '500 g');
      expect(JarStandards.formatKg(0.25), '250 g');
    });

    test('common sadrži standardne veličine tegli', () {
      expect(JarStandards.common.map((j) => j.ml).toList(),
          [200, 370, 720, 1000]);
      expect(JarStandards.commonBottles.map((b) => b.liters).toList(),
          [0.5, 1.0, 2.0]);
      expect(JarStandards.classicLargeJarMl, 720);
    });
  });
}
