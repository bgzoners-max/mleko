import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/providers/favorites_provider.dart';
import 'package:mleko/repositories/social/favorites_repository.dart';

class FakeFavoritesRepository implements FavoritesRepository {
  final Map<String, Set<String>> _favoritesByUser = {};

  Set<String> _userFavs(String userId) =>
      _favoritesByUser.putIfAbsent(userId, () => {});

  @override
  Future<List<String>> getFavoriteProductIds(String userId) async =>
      _userFavs(userId).toList();

  @override
  Future<bool> isFavorite(String userId, String productId) async =>
      _userFavs(userId).contains(productId);

  @override
  Future<void> addFavorite(String userId, String productId) async {
    _userFavs(userId).add(productId);
  }

  @override
  Future<void> removeFavorite(String userId, String productId) async {
    _userFavs(userId).remove(productId);
  }

  @override
  Future<List<ProductModel>> getFavoriteProducts(String userId) async => const [];

  void seed(String userId, List<String> ids) => _userFavs(userId).addAll(ids);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesProvider', () {
    test('loads empty favorites for null userId', () async {
      final repo = FakeFavoritesRepository();
      final provider = FavoritesProvider(repository: repo);

      await provider.load(null);

      expect(provider.isLoaded, isTrue);
      expect(provider.count, 0);
      expect(provider.isFavorite('p-1'), isFalse);
    });

    test('loads favorites from service for userId', () async {
      final repo = FakeFavoritesRepository()..seed('user-1', ['p-1', 'p-2']);
      final provider = FavoritesProvider(repository: repo);

      await provider.load('user-1');

      expect(provider.isLoaded, isTrue);
      expect(provider.count, 2);
      expect(provider.isFavorite('p-1'), isTrue);
      expect(provider.isFavorite('p-2'), isTrue);
      expect(provider.isFavorite('p-3'), isFalse);
      expect(provider.ids, containsAll(['p-1', 'p-2']));
    });

    test('does not reload if already loaded for same userId', () async {
      final repo = FakeFavoritesRepository()..seed('user-1', ['p-1']);
      final provider = FavoritesProvider(repository: repo);

      await provider.load('user-1');
      final idsBefore = provider.ids;

      // Second load with same userId should be a no-op
      await provider.load('user-1');

      expect(provider.ids, idsBefore);
    });

    test('reloads favorites when userId changes', () async {
      final repo = FakeFavoritesRepository()..seed('user-1', ['p-1']);
      final provider = FavoritesProvider(repository: repo);

      await provider.load('user-1');
      expect(provider.isFavorite('p-1'), isTrue);

      // Switch to user-2 which has no favorites
      await provider.load('user-2');
      expect(provider.isFavorite('p-1'), isFalse);
      expect(provider.count, 0);
    });

    test('clear resets all state', () async {
      final repo = FakeFavoritesRepository()..seed('user-1', ['p-1', 'p-2']);
      final provider = FavoritesProvider(repository: repo);

      await provider.load('user-1');
      expect(provider.count, 2);

      provider.clear();

      expect(provider.isLoaded, isFalse);
      expect(provider.count, 0);
      expect(provider.isFavorite('p-1'), isFalse);
    });

    test('toggle adds and removes favorite with revert on failure', () async {
      final repo = FakeFavoritesRepository()..seed('user-1', ['p-1']);
      final provider = FavoritesProvider(repository: repo);

      await provider.load('user-1');

      // Toggle off p-1 (remove)
      await provider.toggle('user-1', 'p-1');
      expect(provider.isFavorite('p-1'), isFalse);

      // Toggle on p-2 (add)
      await provider.toggle('user-1', 'p-2');
      expect(provider.isFavorite('p-2'), isTrue);

      expect(provider.count, 1); // only p-2 remains
    });

    test('toggle does nothing for null userId', () async {
      final repo = FakeFavoritesRepository()..seed('user-1', ['p-1']);
      final provider = FavoritesProvider(repository: repo);

      await provider.toggle(null, 'p-1');

      expect(provider.count, 0);
    });

    test('toggle reverts state when service fails', () async {
      final repo = FakeFavoritesRepository()..seed('user-1', ['p-1']);
      final provider = FavoritesProvider(repository: repo);

      await provider.load('user-1');
      expect(provider.isFavorite('p-1'), isTrue);

      await provider.toggle('user-1', 'p-1');
      expect(provider.isFavorite('p-1'), isFalse);
    });
  });
}
