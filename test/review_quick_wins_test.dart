import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/main.dart';
import 'package:mleko/services/media/storage_service.dart';

void main() {
  group('GlobalScrollBehavior (a11y scrollbar)', () {
    testWidgets('prikazuje Scrollbar na desktop platformi',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          scrollBehavior: GlobalScrollBehavior(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(height: 2000, child: Text('sadrzaj')),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Scrollbar), findsWidgets);
    });

    testWidgets('ne prikazuje Scrollbar na touch platformi (Android)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          scrollBehavior: GlobalScrollBehavior(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(height: 2000, child: Text('sadrzaj')),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Scrollbar), findsNothing);
    });
  });

  group('StorageService.extractPathFromPublicUrl', () {
    test('izdvaja putanju i odbacuje query parametre', () {
      expect(
        StorageService.extractPathFromPublicUrl(
          'product-images',
          'https://x.supabase.co/storage/v1/object/public/product-images/uid/abc.jpg?t=123',
        ),
        'uid/abc.jpg',
      );
    });

    test('radi za ostale buckete', () {
      expect(
        StorageService.extractPathFromPublicUrl(
          'farm-gallery',
          'https://x.supabase.co/storage/v1/object/public/farm-gallery/s1/foto.webp',
        ),
        's1/foto.webp',
      );
    });

    test('vraca null za pogresan bucket ili praznu putanju', () {
      expect(
        StorageService.extractPathFromPublicUrl(
          'product-images',
          'https://x.supabase.co/storage/v1/object/public/drugi-bucket/a.jpg',
        ),
        isNull,
      );
      expect(
        StorageService.extractPathFromPublicUrl(
          'product-images',
          'https://x.supabase.co/storage/v1/object/public/product-images/',
        ),
        isNull,
      );
    });
  });
}
