import 'package:flutter/foundation.dart';
import 'package:mleko/services/services.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _service;
  Set<String> _ids = {};
  bool _loaded = false;
  String? _loadedUserId;

  FavoritesProvider({FavoritesService? service})
      : _service = service ?? FavoritesService();

  List<String> get ids => List.unmodifiable(_ids.toList());
  Set<String> get idSet => Set.unmodifiable(_ids);
  int get count => _ids.length;
  bool get isLoaded => _loaded;

  Future<void> load(String? userId) async {
    if (userId == null) {
      _ids = {};
      _loaded = true;
      _loadedUserId = null;
      notifyListeners();
      return;
    }
    if (_loaded && _loadedUserId == userId) return;
    try {
      final fetched = await _service.getFavoriteProductIds(userId);
      _ids = fetched.toSet();
      _loadedUserId = userId;
    } catch (e, st) {
      LoggerService.error('Failed to load favorites', e, stackTrace: st);
      _ids = {};
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  void clear() {
    _ids = {};
    _loaded = false;
    _loadedUserId = null;
    notifyListeners();
  }

  final Set<String> _togglingIds = {};

  Future<void> toggle(String? userId, String productId) async {
    if (userId == null) return;
    if (_togglingIds.contains(productId)) return;
    _togglingIds.add(productId);
    final wasFavorite = _ids.contains(productId);
    if (wasFavorite) {
      _ids.remove(productId);
    } else {
      _ids.add(productId);
    }
    notifyListeners();
    try {
      if (wasFavorite) {
        await _service.removeFavorite(userId, productId);
      } else {
        await _service.addFavorite(userId, productId);
      }
    } catch (e, st) {
      // Revert state na prethodnu vrednost
      if (wasFavorite) {
        _ids.add(productId);
      } else {
        _ids.remove(productId);
      }
      notifyListeners();

      LoggerService.error('Failed to toggle favorite', e, stackTrace: st);
    } finally {
      _togglingIds.remove(productId);
    }
  }

  bool isFavorite(String productId) => _ids.contains(productId);

  @override
  void dispose() {
    _togglingIds.clear();
    super.dispose();
  }
}

