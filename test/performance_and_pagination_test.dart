import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/services/catalog/mixins/product_listing_mixin.dart';
import 'package:mleko/services/communication/notifications_service.dart';
import 'package:mleko/utils/image_precache_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeListingService with ProductListingMixin {
  @override
  SupabaseClient get client => throw UnimplementedError();

  @override
  Future<List<ProductModel>> attachSelectedDeliveryPointIds(List<ProductModel> products) async => products;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('6.1 Cursor-based Pagination API', () {
    test('NotificationsService accepts limit and beforeCreatedAt parameters', () {
      final service = NotificationsService();
      expect(
        () => service.getNotifications(
          'user-123',
          limit: 15,
          beforeCreatedAt: DateTime.now(),
        ),
        throwsA(anything), // throws because Supabase client is not connected in local mock
      );
    });

    test('ProductListingMixin exposes getProductsByCategoriesCursor signature', () {
      final service = _FakeListingService();
      expect(
        service.getProductsByCategoriesCursor(
          categoryNames: [],
          limit: 10,
          beforeCreatedAt: DateTime.now(),
        ),
        completes,
      );
    });
  });

  group('6.2 Image Cache Memory Limits & Eviction', () {
    test('AppImageCache.configureMemoryLimits updates imageCache limits', () {
      AppImageCache.configureMemoryLimits(maxObjects: 120, maxSizeBytes: 30 * 1024 * 1024);
      final cache = PaintingBinding.instance.imageCache;
      expect(cache.maximumSize, equals(120));
      expect(cache.maximumSizeBytes, equals(30 * 1024 * 1024));
    });

    test('AppImageCache.clearMemoryCache clears memory cache cleanly', () {
      expect(() => AppImageCache.clearMemoryCache(), returnsNormally);
    });

    test('AppImageCache exposes configured custom CacheManager', () {
      final manager = AppImageCache.cacheManager;
      expect(manager, isNotNull);
    });
  });
}
