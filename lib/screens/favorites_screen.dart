import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/app_state.dart';
import '../providers/favorites_provider.dart';
import 'package:mleko/services/services.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/skeleton.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favoritesService = FavoritesService();
  final _refreshController = StreamController<void>.broadcast();
  final _scrollController = ScrollController();

  /// Stream keširan da se na svakom rebuild-u ne kreira novi i ne ponovo učitavaju omiljeni.
  Stream<List<ProductModel>>? _favoritesStream;
  String? _streamUserId;

  static const _pageSize = 20;
  int _displayCount = _pageSize;

  void _initStream(String userId) {
    if (_streamUserId == userId) return;
    _streamUserId = userId;
    _displayCount = _pageSize;
    _favoritesStream = _favoritesService.streamFavoriteProducts(
      userId,
      refreshTrigger: _refreshController.stream,
    );
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      setState(() => _displayCount += _pageSize);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AppState>().user;
    final favorites = context.read<FavoritesProvider>();
    if (user != null && !user.isGuest && !favorites.isLoaded) {
      favorites.load(user.id);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _refreshController.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    _refreshController.add(null);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Omiljeni proizvodi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Prijavite se da sačuvate omiljene proizvode', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Prijavi se'),
              ),
            ],
          ),
        ),
      );
    }

    _initStream(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Omiljeni proizvodi')),
      body: StreamBuilder<List<ProductModel>>(
        stream: _favoritesStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju omiljenih.',
              detail: snap.error?.toString(),
              onRetry: () => _refreshController.add(null),
            );
          }
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ProductListSkeleton();
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: AppEmptyState(
                    icon: Icons.favorite_border,
                    title: 'Nemate omiljenih proizvoda',
                    subtitle: 'Dodajte srcem na karticama proizvoda da ih nađete brzo ovde.',
                    ctaLabel: 'Pretraži proizvode',
                    ctaIcon: Icons.search,
                    onCtaPressed: () => context.go('/'),
                  ),
                ),
              ),
            );
          }
          final visible = list.take(_displayCount).toList();
          final hasMore = list.length > _displayCount;
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: visible.length + (hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == visible.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final p = visible[i];
                return Selector<FavoritesProvider, bool>(
                  selector: (_, fav) => fav.isFavorite(p.id),
                  builder: (_, isFavorite, __) {
                    final user = context.watch<AppState>().user;
                    final favorites = context.read<FavoritesProvider>();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ProductCard(
                        product: p,
                        isFavorite: isFavorite,
                        onFavoriteToggle: user != null && !user.isGuest
                            ? () => favorites.toggle(user.id, p.id)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

