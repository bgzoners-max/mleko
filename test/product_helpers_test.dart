import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/product_helpers.dart';

void main() {
  group('isVolumeCategory', () {
    test('prepoznaje tečne kategorije i vraća true', () {
      expect(isVolumeCategory('Kravlje mleko'), isTrue);
      expect(isVolumeCategory('Prirodni sok'), isTrue);
      expect(isVolumeCategory('Bazga sirup'), isTrue);
      expect(isVolumeCategory('Hladno ceđeno ulje'), isTrue);
      expect(isVolumeCategory('Jabukovo sirće'), isTrue);
      expect(isVolumeCategory('Domaća rakija'), isTrue);
    });

    test('vraća false za čvrste i specifične REPO_BIBLE kategorije', () {
      expect(isVolumeCategory('Med'), isFalse);
      expect(isVolumeCategory('Livadski med'), isFalse);
      expect(isVolumeCategory('Zimnica'), isFalse);
      expect(isVolumeCategory('Kačkavalj'), isFalse);
      expect(isVolumeCategory('Beli sir'), isFalse);
      expect(isVolumeCategory('Puter'), isFalse);
    });
  });
}
