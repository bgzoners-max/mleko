import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/repositories/social/favorite_sellers_repository.dart';
import 'package:mleko/services/social/favorite_sellers_service.dart';

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

class FakeFavoriteSellersRepository implements FavoriteSellersRepository {
  final Map<String, Set<String>> _following = {};
  final List<ProductModel> products = [];
  final List<UserModel> profiles = [];

  @override
  Future<List<String>> getFavoriteSellerIds(String userId) async {
    return _following[userId]?.toList() ?? [];
  }

  @override
  Future<bool> isFollowing(String userId, String sellerId) async {
    return _following[userId]?.contains(sellerId) ?? false;
  }

  @override
  Future<void> follow(String userId, String sellerId) async {
    _following.putIfAbsent(userId, () => {}).add(sellerId);
  }

  @override
  Future<void> unfollow(String userId, String sellerId) async {
    _following[userId]?.remove(sellerId);
  }

  @override
  Future<List<ProductModel>> getProductsFromFavoriteSellers(
      String userId) async {
    final sellerIds = _following[userId] ?? {};
    return products.where((p) => sellerIds.contains(p.sellerId)).toList();
  }

  @override
  Future<int> getFollowersCount(String sellerId) async {
    var count = 0;
    for (final set in _following.values) {
      if (set.contains(sellerId)) count++;
    }
    return count;
  }

  @override
  Future<List<UserModel>> getFavoriteSellersWithProfiles(String userId) async {
    final sellerIds = _following[userId] ?? {};
    return profiles.where((u) => sellerIds.contains(u.id)).toList();
  }
}

void main() {
  group('FavoriteSellersRepository & FavoriteSellersService test', () {
    late FakeFavoriteSellersRepository fakeRepo;
    late FavoriteSellersService service;

    setUp(() {
      fakeRepo = FakeFavoriteSellersRepository();
      service = FavoriteSellersService(repository: fakeRepo);
    });

    test('follow, unfollow i toggleFollow rade ispravno', () async {
      expect(await service.isFollowing('u1', 's1'), isFalse);

      await service.follow('u1', 's1');
      expect(await service.isFollowing('u1', 's1'), isTrue);
      expect(await service.getFollowersCount('s1'), 1);

      await service.toggleFollow('u1', 's1');
      expect(await service.isFollowing('u1', 's1'), isFalse);
      expect(await service.getFollowersCount('s1'), 0);
    });

    test('getProductsFromFavoriteSellers vraća proizvode samo praćenih prodavaca',
        () async {
      await service.follow('u1', 's1');

      fakeRepo.products.addAll([
        _makeProduct('p1', 's1', 'Domaći sir'),
        _makeProduct('p2', 's2', 'Med'),
      ]);

      final feed = await service.getProductsFromFavoriteSellers('u1');

      expect(feed.length, 1);
      expect(feed.first.name, 'Domaći sir');
    });
  });
}
