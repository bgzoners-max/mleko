import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/haptic.dart';
import '../core/responsive.dart';
import '../constants/amazon_theme.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/cart_provider.dart';
import 'package:mleko/services/services.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/rustic_illustration.dart';
import '../widgets/app_back_button.dart';
import '../widgets/cart/cart_guest_banner.dart';
import '../widgets/cart/cart_seller_group_card.dart';
import '../widgets/skeletons/order_skeletons.dart';

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

    try {
      final profiles = await usersService.getUsers(sellerIds);
      final profilesMap = {for (var p in profiles) p.id: p};

      if (!mounted) return;
      setState(() {
        _groupedItems = grouped;
        _sellerProfiles = profilesMap;
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
        leading: const AppBackButton(fallbackRoute: '/'),
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
          const AppHomeButton(),
        ],
      ),
      body: _loading
          ? const OrderListSkeleton(itemCount: 3)
          : _groupedItems.isEmpty
              ? _buildEmptyState()
              : _buildCartList(),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      motif: RusticMotif.basket,
      icon: Icons.shopping_basket_outlined,
      title: 'Korpa je još prazna',
      subtitle:
          'Dodaj nekoliko domaćih proizvoda i podrži gazdinstva iz svog kraja.',
      ctaLabel: 'Istraži proizvode',
      onCtaPressed: () => context.go('/'),
    );
  }

  Widget _buildCartList() {
    final isWide = Breakpoints.useTwoPaneLayout(context);
    final sellerIds = _groupedItems.keys.toList();
    final cart = context.watch<CartProvider>();
    final showGuestBanner = cart.hasMigratedFromGuest;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
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
                return CartSellerGroupCard(
                  sellerId: sellerId,
                  sellerName: profile?.farmName ??
                      profile?.displayName ?? 'Prodavac',
                  location: profile?.city ?? 'Nepoznata lokacija',
                  items: items,
                  onRefresh: _loadData,
                );
              },
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: CartSummaryPanel(
              total: _calculateTotal(),
              itemCount: cart.count,
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
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
            return CartSellerGroupCard(
              sellerId: sellerId,
              sellerName: profile?.farmName ??
                  profile?.displayName ?? 'Prodavac',
              location: profile?.city ?? 'Nepoznata lokacija',
              items: items,
              onRefresh: _loadData,
            );
          },
        ),
      ),
    );
  }

  double _calculateTotal() {
    return _groupedItems.values.fold<double>(
      0.0,
      (sum, items) => sum + items.fold<double>(0.0, (a, b) => a + b.quantity),
    );
  }
}

/// Desktop sažetak porudžbine — prikazuje ukupan broj stavki i ukupnu cenu.
class CartSummaryPanel extends StatelessWidget {
  final double total;
  final int itemCount;

  const CartSummaryPanel({
    super.key,
    required this.total,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? AmazonColors.darkBorder
        : AmazonColors.borderGray;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: AmazonColors.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 20, color: AmazonColors.getLink(context)),
              const SizedBox(width: 8),
              Text(
                'Sažetak porudžbine',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AmazonColors.getTextPrimary(context),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SummaryRow(
            label: 'Stavki u korpi',
            value: itemCount.toString(),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Ukupna količina',
            value: '${total.toStringAsFixed(1)} kg',
            isDark: isDark,
            isHighlight: true,
          ),
          const Divider(height: 28),
          const SizedBox(height: 8),
          Text(
            'Plaćanje se obavlja direktno proizvođaču pri preuzimanju ili isporuci.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AmazonColors.getTextSecondary(context)),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isHighlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AmazonColors.getTextSecondary(context),
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isHighlight
                    ? AmazonColors.getAmber(context)
                    : AmazonColors.getTextPrimary(context),
              ),
        ),
      ],
    );
  }
}
