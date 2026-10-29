import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mleko/services/media/image_compression_service.dart';

void main() {
  group('ImageCompressionService', () {
    late Uint8List largeTestImageBytes;

    setUpAll(() {
      // Kreiramo veliku test sliku dimenzija 2400x1800
      final image = img.Image(width: 2400, height: 1800);
      img.fill(image, color: img.ColorRgb8(200, 100, 50));
      largeTestImageBytes =
          Uint8List.fromList(img.encodeJpg(image, quality: 95));
    });

    test('compressImage resizes image to max 1200px and reduces size', () async {
      final service = ImageCompressionService();
      final compressed = await service.compressImage(largeTestImageBytes);

      expect(compressed, isNotEmpty);
      expect(compressed.length, lessThan(largeTestImageBytes.length));

      final decoded = img.decodeImage(compressed);
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThanOrEqualTo(1200));
      expect(decoded.height, lessThanOrEqualTo(1200));
    });

    test('compressProfileImage resizes image to max 512px', () async {
      final service = ImageCompressionService();
      final compressed =
          await service.compressProfileImage(largeTestImageBytes);

      expect(compressed, isNotEmpty);
      final decoded = img.decodeImage(compressed);
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThanOrEqualTo(512));
      expect(decoded.height, lessThanOrEqualTo(512));
    });

    test('compressChatImage resizes image to max 1200px', () async {
      final service = ImageCompressionService();
      final compressed = await service.compressChatImage(largeTestImageBytes);

      expect(compressed, isNotEmpty);
      final decoded = img.decodeImage(compressed);
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThanOrEqualTo(1200));
      expect(decoded.height, lessThanOrEqualTo(1200));
    });

    test('gracefully handles non-image bytes by returning original', () async {
      final service = ImageCompressionService();
      final randomBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = await service.compressImage(randomBytes);
      expect(result, equals(randomBytes));
    });
  });
}
