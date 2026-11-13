import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import 'package:mleko/services/services.dart';
import '../widgets/skeleton.dart';
import '../widgets/app_back_button.dart';
import '../widgets/checkout/checkout_multi_form.dart';

/// Checkout više proizvoda od istog prodavca
class CheckoutMultiScreen extends StatefulWidget {
  final String sellerId;
  final Map<String, double> productQuantities;

  const CheckoutMultiScreen({
    super.key,
    required this.sellerId,
    required this.productQuantities,
  });

  @override
  State<CheckoutMultiScreen> createState() => _CheckoutMultiScreenState();
}

class _CheckoutMultiScreenState extends State<CheckoutMultiScreen> {
  List<({ProductModel product, double quantity})>? _items;
  String? _sellerName;
  bool _loading = true;
  String? _error;
  bool _loadFromCartScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.productQuantities.isNotEmpty) {
      _load(widget.productQuantities);
    } else {
      _loadFromCartScheduled = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadFromCartScheduled && mounted) {
      _loadFromCartScheduled = false;
      _loadFromCart();
    }
  }

  Future<void> _loadFromCart() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final cart = context.read<CartProvider>();
      final list = await cart.getProductsBySeller(widget.sellerId);
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() {
          _items = [];
          _sellerName = null;
          _loading = false;
          _error = 'Nema stavki. Dodaj proizvode kod prodavca.';
        });
        return;
      }
      final sellerName = await _fetchSellerName();
      if (!mounted) return;
      setState(() {
        _items = list;
        _sellerName = sellerName;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Greška pri učitavanju korpe. Proverite vezu i pokušajte ponovo.';
      });
    }
  }

  Future<String> _fetchSellerName() async {
    final user = await context.read<UsersService>().getUser(widget.sellerId);
    return user?.farmName ?? user?.displayName ?? 'Domaćinstvo';
  }

  Future<void> _load(Map<String, double> productQuantities) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final productsService = context.read<ProductsService>();
      // Batch load umesto N+1 petlje
      final baseIds = productQuantities.keys
          .map(ProductModel.extractProductId)
          .toSet()
          .toList();
      final products = await productsService.getProductsByIds(baseIds);
      final items = <({ProductModel product, double quantity})>[];
      for (final e in productQuantities.entries) {
        final baseId = ProductModel.extractProductId(e.key);
        final p = products[baseId];
        if (p != null && p.sellerId == widget.sellerId) {
          items.add((product: p.resolveForCartKey(e.key), quantity: e.value));
        }
      }
      final sellerName = items.isNotEmpty ? await _fetchSellerName() : null;
      if (mounted) {
        setState(() {
          _items = items;
          _sellerName = sellerName;
          _loading = false;
          if (items.isEmpty) {
            _error = 'Nema stavki. Dodaj proizvode kod prodavca.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Greška pri učitavanju porudžbine. Pokušajte ponovo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: AppBackButton(fallbackRoute: '/seller/${widget.sellerId}'),
          title: const Text('Porudžbina'),
          actions: const [AppHomeButton()],
        ),
        body: const ProductDetailSkeleton(),
      );
    }
    if (_error != null || _items == null || _items!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: AppBackButton(fallbackRoute: '/seller/${widget.sellerId}'),
          title: const Text('Porudžbina'),
          actions: const [AppHomeButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_basket_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Nema stavki. Dodaj proizvode kod prodavca.',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        if (widget.productQuantities.isNotEmpty) {
                          _load(widget.productQuantities);
                        } else {
                          _loadFromCart();
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Pokušaj ponovo'),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/seller/${widget.sellerId}'),
                      icon: const Icon(Icons.store),
                      label: const Text('Nazad kod prodavca'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return CheckoutMultiForm(
      sellerId: widget.sellerId,
      sellerName: _sellerName ?? 'Domaćinstvo',
      items: _items!,
    );
  }
}
