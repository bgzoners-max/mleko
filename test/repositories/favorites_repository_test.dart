import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/repositories/social/favorites_repository.dart';
import 'package:mleko/services/social/favorites_service.dart';

ProductModel _makeProduct(String id, String sellerId, String name) {
  return ProductModel(
    id: id,
    sellerId: sellerId,
    name: name,
    category: 'Mleko',
    pricePerKg: 100,
    minOrderKg: 1,
    availableKg: 10,
    description: 'Test',
    imageUrls: const [],
    pickupOptions: const [],
    location: 'Beograd',
    createdAt: DateTime.now(),
  );
}

class FakeFavoritesRepository implements FavoritesRepository {
  final List<String> favoriteIds = [];
  final List<ProductModel> products = [];

  @override
  Future<List<String>> getFavoriteProductIds(String userId) async {
    return List.unmodifiable(favoriteIds);
  }

  @override
  Future<bool> isFavorite(String userId, String productId) async {
    return favoriteIds.contains(productId);
  }

  @override
  Future<void> addFavorite(String userId, String productId) async {
    if (!favoriteIds.contains(productId)) {
      favoriteIds.add(productId);
    }
  }

  @override
  Future<void> removeFavorite(String userId, String productId) async {
    favoriteIds.remove(productId);
  }

  @override
  Future<List<ProductModel>> getFavoriteProducts(String userId) async {
    return products.where((p) => favoriteIds.contains(p.id)).toList();
  }
}

void main() {
  group('FavoritesRepository & FavoritesService integracija', () {
    late FakeFavoritesRepository fakeRepo;
    late FavoritesService service;

    setUp(() {
      fakeRepo = FakeFavoritesRepository();
      service = FavoritesService(repository: fakeRepo);
    });

    test('getFavoriteProductIds čita iz repozitorijuma bez Supabase klijenta',
        () async {
      fakeRepo.favoriteIds.addAll(['p1', 'p2', 'p3']);

      final result = await service.getFavoriteProductIds('user-1');

      expect(result, ['p1', 'p2', 'p3']);
    });

    test('addFavorite i removeFavorite menjaju stanje u repozitorijumu', () async {
      expect(await service.isFavorite('user-1', 'p1'), isFalse);

      await service.addFavorite('user-1', 'p1');
      expect(await service.isFavorite('user-1', 'p1'), isTrue);

      await service.removeFavorite('user-1', 'p1');
      expect(await service.isFavorite('user-1', 'p1'), isFalse);
    });

    test('getFavoriteProducts filtrira proizvode po omiljenim ID-jevima',
        () async {
      final p1 = _makeProduct('p1', 's1', 'Mleko');
      final p2 = _makeProduct('p2', 's1', 'Sir');
      fakeRepo.products.addAll([p1, p2]);
      fakeRepo.favoriteIds.add('p1');

      final favorites = await service.getFavoriteProducts('user-1');

      expect(favorites.length, 1);
      expect(favorites.first.name, 'Mleko');
    });
  });
}
