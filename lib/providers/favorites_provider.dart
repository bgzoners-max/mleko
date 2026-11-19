import 'package:flutter/foundation.dart';
import 'package:mleko/repositories/repositories.dart';
import 'package:mleko/services/services.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _service;
  Set<String> _ids = {};
  bool _loaded = false;
  bool _isDisposed = false;
  String? _loadedUserId;

  FavoritesProvider({
    FavoritesService? service,
    FavoritesRepository? repository,
  }) : _service = service ?? FavoritesService(repository: repository);

  List<String> get ids => List.unmodifiable(_ids.toList());
  Set<String> get idSet => Set.unmodifiable(_ids);
  int get count => _ids.length;
  bool get isLoaded => _loaded;

  int _loadSession = 0;

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> load(String? userId) async {
    if (_isDisposed) return;
    final session = ++_loadSession;
    if (userId == null) {
      _ids = {};
      _loaded = true;
      _loadedUserId = null;
      _safeNotifyListeners();
      return;
    }
    if (_loaded && _loadedUserId == userId) return;
    try {
      final fetched = await _service.getFavoriteProductIds(userId);
      if (_isDisposed || session != _loadSession) return;
      _ids = fetched.toSet();
      _loadedUserId = userId;
      _loaded = true;
      _safeNotifyListeners();
    } catch (e, st) {
      if (_isDisposed || session != _loadSession) return;
      LoggerService.error('Failed to load favorites', e, stackTrace: st);
      _ids = {};
      _loaded = false;
      _loadedUserId = null;
      _safeNotifyListeners();
    }
  }

  void clear() {
    _loadSession++;
    _togglingIds.clear();
    _ids = {};
    _loaded = false;
    _loadedUserId = null;
    _safeNotifyListeners();
  }

  final Set<String> _togglingIds = {};

  Future<void> toggle(String? userId, String productId) async {
    if (_isDisposed || userId == null) return;
    if (_togglingIds.contains(productId)) return;
    final session = _loadSession;
    _togglingIds.add(productId);
    final wasFavorite = _ids.contains(productId);
    if (wasFavorite) {
      _ids.remove(productId);
    } else {
      _ids.add(productId);
    }
    _safeNotifyListeners();
    try {
      if (wasFavorite) {
        await _service.removeFavorite(userId, productId);
      } else {
        await _service.addFavorite(userId, productId);
      }
    } catch (e, st) {
      // Revert state samo ako korisnička sesija i dalje odgovara (sprečava curenje između naloga)
      if (!_isDisposed && session == _loadSession) {
        if (wasFavorite) {
          _ids.add(productId);
        } else {
          _ids.remove(productId);
        }
        _safeNotifyListeners();
      }

      LoggerService.error('Failed to toggle favorite', e, stackTrace: st);
    } finally {
      _togglingIds.remove(productId);
    }
  }

  bool isFavorite(String productId) => _ids.contains(productId);

  @override
  void dispose() {
    _isDisposed = true;
    _loadSession++;
    _togglingIds.clear();
    super.dispose();
  }
}
