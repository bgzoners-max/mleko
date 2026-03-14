class JarSizeStandard {
  final int ml;
  final String typicalUse;

  const JarSizeStandard({required this.ml, required this.typicalUse});
}

class BottleSizeStandard {
  final double liters;
  final String typicalUse;

  const BottleSizeStandard({required this.liters, required this.typicalUse});
}

class NetMassRangeKg {
  final double minKg;
  final double maxKg;

  const NetMassRangeKg({required this.minKg, required this.maxKg});
}

class JarStandards {
  static const int classicLargeJarMl = 720;

  // Najcesce velicine koje korisnici unose za zimnicu, namaze i med.
  static const List<JarSizeStandard> common = [
    JarSizeStandard(ml: 200, typicalUse: 'manje tegle za namaze, senf, ren'),
    JarSizeStandard(ml: 370, typicalUse: 'srednja tegla, cesto za med i dzem'),
    JarSizeStandard(
        ml: 720, typicalUse: 'standardna velika tegla za zimnicu, dzem i med'),
    JarSizeStandard(ml: 1000, typicalUse: 'velika tegla za zimnicu i tursiju'),
  ];

  static const List<BottleSizeStandard> commonBottles = [
    BottleSizeStandard(liters: 0.5, typicalUse: 'sok, sirup, rakija'),
    BottleSizeStandard(liters: 1.0, typicalUse: 'mleko, sok, sirup'),
    BottleSizeStandard(liters: 2.0, typicalUse: 'porodicna pakovanja sokova'),
  ];

  static bool isHoneyLike(String text) {
    final t = text.toLowerCase();
    return t.contains('med') || t.contains('honey') || t.contains('pcel');
  }

  static double litersFromMl(int ml) => ml / 1000.0;

  // Referentna aproksimacija iz zahteva: 720 ml ~= 1 kg meda.
  static double honeyKgFromMl(int ml) => ml / classicLargeJarMl;

  // Opsti opseg za gustu/retku zimnicu iz zahteva: 720 ml ~= 700-900 g.
  static NetMassRangeKg genericNetRangeKgFromMl(int ml) {
    final minKg = (ml * (700 / 720)) / 1000;
    final maxKg = (ml * (900 / 720)) / 1000;
    return NetMassRangeKg(minKg: minKg, maxKg: maxKg);
  }

  static String formatKg(double valueKg) {
    if (valueKg >= 1 && valueKg.truncateToDouble() == valueKg) {
      return '${valueKg.toStringAsFixed(0)} kg';
    }
    if (valueKg >= 1) {
      return '${valueKg.toStringAsFixed(2)} kg';
    }
    final grams = (valueKg * 1000).round();
    return '$grams g';
  }
}
