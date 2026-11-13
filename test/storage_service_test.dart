import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/services/media/storage_service.dart';

void main() {
  group('StorageService.detectMimeAndExt', () {
    test('prepoznaje validan JPEG po magic bajtovima', () {
      final result = StorageService.detectMimeAndExt([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);
      expect(result.ext, 'jpg');
      expect(result.mimeType, 'image/jpeg');
    });

    test('prepoznaje validan PNG po magic bajtovima', () {
      final result = StorageService.detectMimeAndExt([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00,
      ]);
      expect(result.ext, 'png');
      expect(result.mimeType, 'image/png');
    });

    test('prepoznaje validan WebP (RIFF....WEBP sa 0x50 za P)', () {
      final result = StorageService.detectMimeAndExt([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x24, 0x00, 0x00, 0x00, // veličina
        0x57, 0x45, 0x42, 0x50, // WEBP
      ]);
      expect(result.ext, 'webp');
      expect(result.mimeType, 'image/webp');
    });

    test('ne prepoznaje WEB@ (0x40) kao WebP već vraća fallback', () {
      final result = StorageService.detectMimeAndExt([
        0x52, 0x49, 0x46, 0x46,
        0x24, 0x00, 0x00, 0x00,
        0x57, 0x45, 0x42, 0x40,
      ]);
      expect(result.mimeType, isNot('image/webp'));
    });
  });
}

