import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

/// Deljeni golden-test helperi.
///
/// Upotreba u golden test fajlu:
/// ```dart
/// goldenFileComparator = TolerantGoldenFileComparator(
///   Uri.parse('test/golden/moj_test_golden_test.dart'),
///   maxDiffRatio: 0.005,
/// );
/// ```
///
/// Regeneracija goldena: `flutter test --update-goldens test/golden/`.

/// Golden komparator koji toleriše mali pixel diff (do [maxDiffRatio]) kako
/// golden testovi ne bi padali zbog razlika u rasterizaciji između platformi
/// (Windows/Linux — AA šum od ~0.01% piksela na ivicama ikona). Iza praga se
/// i dalje tretira kao failure.
class TolerantGoldenFileComparator extends LocalFileComparator {
  TolerantGoldenFileComparator(super.testFile, {required this.maxDiffRatio});

  final double maxDiffRatio;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) return true;

    final diffPercent = result.diffPercent;
    if (diffPercent <= maxDiffRatio) {
      debugPrint(
          'Golden (tolerisano): ${golden.path} — diff ${(diffPercent * 100).toStringAsFixed(3)}% <= ${(maxDiffRatio * 100).toStringAsFixed(2)}%');
      return true;
    }
    return super.compare(imageBytes, golden);
  }
}
