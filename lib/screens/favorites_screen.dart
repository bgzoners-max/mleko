import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/favorites_provider.dart';
import '../services/favorites_service.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favoritesService = FavoritesService();
  final _refreshController = StreamController<void>.broadcast();

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

    return Scaffold(
      appBar: AppBar(title: const Text('Omiljeni proizvodi')),
      body: StreamBuilder(
        stream: _favoritesService.streamFavoriteProducts(user.id, refreshTrigger: _refreshController.stream),
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju omiljenih.',
              detail: snap.error?.toString(),
              onRetry: () => _refreshController.add(null),
            );
          }
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Nemate omiljenih proizvoda', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('Dodajte srcem na karticama proizvoda', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];
                final user = context.watch<AppState>().user;
                final favorites = context.watch<FavoritesProvider>();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ProductCard(
                    product: p,
                    isFavorite: true,
                    onFavoriteToggle: () => favorites.toggle(user!.id, p.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
