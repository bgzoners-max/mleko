import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/haptic.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/cart_provider.dart';
import 'package:mleko/services/services.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/cart/cart_guest_banner.dart';
import '../widgets/cart/cart_seller_group_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _loading = true;
  Map<String, List<({ProductModel product, double quantity})>> _groupedItems =
      {};
  Map<String, UserModel> _sellerProfiles = {};
  Map<String, double> _sellerMinimums = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cart = context.read<CartProvider>();
    final grouped = await cart.getProductsGroupedBySeller();
    if (!mounted) return;

    if (grouped.isEmpty) {
      setState(() {
        _groupedItems = {};
        _loading = false;
      });
      return;
    }

    final sellerIds = grouped.keys.toList();
    final usersService = context.read<UsersService>();
    final deliveryService = SellerDeliveryService();

    try {
      final profiles = await usersService.getUsers(sellerIds);
      final profilesMap = {for (var p in profiles) p.id: p};

      final minsMap = <String, double>{};
      for (final sid in sellerIds) {
        final points = await deliveryService.getSellerDeliveryPoints(sid,
            onlyActive: true);
        double? minOrder;
        for (final p in points) {
          for (final s in p.activeSlots) {
            if (s.minOrderAmountRsd != null) {
              if (minOrder == null || s.minOrderAmountRsd! < minOrder) {
                minOrder = s.minOrderAmountRsd;
              }
            }
          }
        }
        if (minOrder != null) minsMap[sid] = minOrder;
      }

      if (!mounted) return;
      setState(() {
        _groupedItems = grouped;
        _sellerProfiles = profilesMap;
        _sellerMinimums = minsMap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Korpa'),
        actions: [
          if (!_loading && _groupedItems.isNotEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Isprazni korpu?'),
                    content:
                        const Text('Svi proizvodi će biti uklonjeni iz korpe.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Odustani')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Isprazni')),
                    ],
                  ),
                );
                if (ok == true) {
                  unawaited(AppHaptics.light());
                  await cart.clear();
                  unawaited(_loadData());
                }
              },
              child: const Text('Isprazni'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groupedItems.isEmpty
              ? _buildEmptyState()
              : _buildCartList(),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.shopping_basket_outlined,
      title: 'Vaša korpa je prazna',
      subtitle:
          'Dodajte domaće proizvode u korpu i podržite lokalne proizvođače.',
      ctaLabel: 'Istraži proizvode',
      onCtaPressed: () => context.go('/'),
    );
  }

  Widget _buildCartList() {
    final isWide = Breakpoints.useTwoPaneLayout(context);
    final sellerIds = _groupedItems.keys.toList();
    final cart = context.watch<CartProvider>();
    final showGuestBanner = cart.hasMigratedFromGuest;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 800 : double.infinity),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sellerIds.length + (showGuestBanner ? 1 : 0),
          itemBuilder: (context, index) {
            if (showGuestBanner && index == 0) {
              return CartGuestBanner(
                onDismiss: () =>
                    context.read<CartProvider>().dismissGuestCartBanner(),
              );
            }

            final sellerIndex = showGuestBanner ? index - 1 : index;
            final sellerId = sellerIds[sellerIndex];
            final items = _groupedItems[sellerId] ?? [];
            final profile = _sellerProfiles[sellerId];
            final minOrder = _sellerMinimums[sellerId];

            return CartSellerGroupCard(
              sellerId: sellerId,
              sellerName:
                  profile?.farmName ?? profile?.displayName ?? 'Prodavac',
              location: profile?.city ?? 'Nepoznata lokacija',
              items: items,
              minOrder: minOrder,
              onRefresh: _loadData,
            );
          },
        ),
      ),
    );
  }
}
