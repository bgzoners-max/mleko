import 'package:flutter/foundation.dart';
import 'package:mleko/services/services.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _service = FavoritesService();
  List<String> _ids = [];
  bool _loaded = false;

  List<String> get ids => List.unmodifiable(_ids);
  bool get isLoaded => _loaded;

  Future<void> load(String? userId) async {
    if (userId == null) {
      _ids = [];
      _loaded = true;
      notifyListeners();
      return;
    }
    _ids = await _service.getFavoriteProductIds(userId);
    _loaded = true;
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
      await _service.toggleFavorite(userId, productId);
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
}

