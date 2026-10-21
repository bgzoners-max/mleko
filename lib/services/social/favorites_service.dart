import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../../repositories/social/favorites_repository.dart';
import '../core/logger_service.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();

  factory FavoritesService({
    FavoritesRepository? repository,
    SupabaseClient? client,
  }) {
    if (repository != null || client != null) {
      return FavoritesService._(repository: repository, client: client);
    }
    return _instance;
  }

  FavoritesService._({FavoritesRepository? repository, SupabaseClient? client})
      : _repository = repository ?? SupabaseFavoritesRepository(client: client);

  FavoritesService._internal()
      : _repository = SupabaseFavoritesRepository();

  final FavoritesRepository _repository;

  Future<List<String>> getFavoriteProductIds(String userId) async {
    try {
      return await _repository.getFavoriteProductIds(userId);
    } catch (e, st) {
      LoggerService.error('Failed to load favorite product IDs', e,
          stackTrace: st);
      rethrow;
    }
  }

  Future<bool> isFavorite(String userId, String productId) async {
    try {
      return await _repository.isFavorite(userId, productId);
    } catch (e, st) {
      LoggerService.error('Failed to check favorite status', e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> addFavorite(String userId, String productId) async {
    try {
      await _repository.addFavorite(userId, productId);
    } catch (e, st) {
      LoggerService.error('Failed to add favorite', e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> removeFavorite(String userId, String productId) async {
    try {
      await _repository.removeFavorite(userId, productId);
    } catch (e, st) {
      LoggerService.error('Failed to remove favorite', e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<ProductModel>> getFavoriteProducts(String userId) async {
    return _repository.getFavoriteProducts(userId);
  }

  Stream<List<ProductModel>> streamFavoriteProducts(String userId,
      {Stream<void>? refreshTrigger}) async* {
    final controller = StreamController<void>();

    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!controller.isClosed) controller.add(null);
    });

    StreamSubscription? triggerSub;
    if (refreshTrigger != null) {
      triggerSub = refreshTrigger.listen((_) {
        if (!controller.isClosed) controller.add(null);
      });
    }

    try {
      yield await getFavoriteProducts(userId);

      await for (final _ in controller.stream) {
        yield await getFavoriteProducts(userId);
      }
    } finally {
      timer.cancel();
      await triggerSub?.cancel();
      await controller.close();
    }
  }
}
