import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/image_url_utils.dart';

void main() {
  group('ImageUrlUtils', () {
    setUp(() {
      ImageUrlUtils.serverTransformsEnabled = true;
    });

    tearDown(() {
      ImageUrlUtils.serverTransformsEnabled = false;
    });

    const validSupabaseUrl =
        'https://xyz.supabase.co/storage/v1/object/public/products/item123.jpg';

    test('returns null when serverTransformsEnabled is false', () {
      ImageUrlUtils.serverTransformsEnabled = false;
      expect(ImageUrlUtils.thumbnailUrl(validSupabaseUrl), isNull);
      expect(ImageUrlUtils.iconUrl(validSupabaseUrl), isNull);
      expect(ImageUrlUtils.detailUrl(validSupabaseUrl), isNull);
    });

    test('thumbnailUrl converts object/public to render/image/public with default width 400 and quality 80', () {
      final thumb = ImageUrlUtils.thumbnailUrl(validSupabaseUrl);
      expect(thumb, isNotNull);
      expect(
        thumb,
        'https://xyz.supabase.co/storage/v1/render/image/public/products/item123.jpg?width=400&quality=80',
      );
    });

    test('thumbnailUrl supports custom width and quality', () {
      final thumb = ImageUrlUtils.thumbnailUrl(validSupabaseUrl, width: 300, quality: 75);
      expect(thumb, isNotNull);
      expect(
        thumb,
        'https://xyz.supabase.co/storage/v1/render/image/public/products/item123.jpg?width=300&quality=75',
      );
    });

    test('iconUrl formats width and height square dimensions', () {
      final icon = ImageUrlUtils.iconUrl(validSupabaseUrl, size: 120);
      expect(icon, isNotNull);
      expect(
        icon,
        'https://xyz.supabase.co/storage/v1/render/image/public/products/item123.jpg?width=120&height=120&quality=80',
      );
    });

    test('detailUrl formats larger width for product detail screen', () {
      final detail = ImageUrlUtils.detailUrl(validSupabaseUrl, width: 800);
      expect(detail, isNotNull);
      expect(
        detail,
        'https://xyz.supabase.co/storage/v1/render/image/public/products/item123.jpg?width=800&quality=85',
      );
    });

    test('transformUrl supports optional resize mode', () {
      final custom = ImageUrlUtils.transformUrl(
        validSupabaseUrl,
        width: 500,
        height: 250,
        quality: 90,
        resize: 'contain',
      );
      expect(custom, isNotNull);
      expect(
        custom,
        'https://xyz.supabase.co/storage/v1/render/image/public/products/item123.jpg?width=500&height=250&quality=90&resize=contain',
      );
    });

    test('returns null for external URLs (not supabase storage)', () {
      expect(ImageUrlUtils.thumbnailUrl('https://example.com/photo.jpg'), isNull);
      expect(ImageUrlUtils.iconUrl('https://images.unsplash.com/photo-123'), isNull);
    });

    test('returns null for URLs that already contain query parameters', () {
      expect(
        ImageUrlUtils.thumbnailUrl('$validSupabaseUrl?token=signed_123'),
        isNull,
      );
    });

    test('returns null for empty string', () {
      expect(ImageUrlUtils.thumbnailUrl(''), isNull);
      expect(ImageUrlUtils.transformUrl(''), isNull);
    });
  });
}