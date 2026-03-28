import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_item_model.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import '../providers/cart_provider.dart';
import 'package:mleko/services/services.dart';
import '../models/product_model.dart';

import '../widgets/offline_indicator.dart';

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
  }

  Future<String> _fetchSellerName() async {
    final prof = await Supabase.instance.client
        .from('profiles')
        .select('farm_name, display_name')
        .eq('id', widget.sellerId)
        .maybeSingle();
    return prof?['farm_name'] ?? prof?['display_name'] ?? 'Domaćinstvo';
  }

  Future<void> _load(Map<String, double> productQuantities) async {
    final productsService = ProductsService();
    // Batch load umesto N+1 petlje
    final products = await productsService.getProductsByIds(productQuantities.keys.toList());
    final items = <({ProductModel product, double quantity})>[];
    for (final e in productQuantities.entries) {
      final p = products[e.key];
      if (p != null && p.sellerId == widget.sellerId) {
        items.add((product: p, quantity: e.value));
      }
    }
    String? sellerName;
    if (items.isNotEmpty) {
      sellerName = await _fetchSellerName();
    }
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
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Porudžbina')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _items == null || _items!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Porudžbina')),
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
                FilledButton.icon(
                  onPressed: () => context.go('/seller/${widget.sellerId}'),
                  icon: const Icon(Icons.store),
                  label: const Text('Nazad kod prodavca'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _CheckoutMultiForm(
      sellerId: widget.sellerId,
      sellerName: _sellerName ?? 'Domaćinstvo',
      items: _items!,
    );
  }
}

class _CheckoutMultiForm extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final List<({ProductModel product, double quantity})> items;

  const _CheckoutMultiForm({
    required this.sellerId,
    required this.sellerName,
    required this.items,
  });

  @override
  State<_CheckoutMultiForm> createState() => _CheckoutMultiFormState();
}

class _CheckoutMultiFormState extends State<_CheckoutMultiForm> {
  late List<({ProductModel product, double quantity})> _items;
  final _noteController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _sending = false;
  String? _error;
  bool _savePhoneToProfile = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    final user = context.read<AppState>().user;
    if (user != null) {
      if (user.city != null && user.city!.isNotEmpty) {
        _cityController.text = user.city!;
      }
      if (user.address != null && user.address!.isNotEmpty) {
        _addressController.text = user.address!;
      }
      if (user.phone != null && user.phone!.isNotEmpty) {
        _phoneController.text = user.phone!;
      }
      _savePhoneToProfile = user.phone == null || user.phone!.isEmpty;
    }
  }

  @override
  void didUpdateWidget(covariant _CheckoutMultiForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) _items = List.from(widget.items);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _setQuantity(int index, double quantity) {
    final p = _items[index].product;
    if (quantity < p.minOrderKg) return;
    setState(() => _items[index] = (product: p, quantity: quantity));
    context.read<CartProvider>().setQuantityForSeller(
          sellerId: widget.sellerId,
          productId: p.id,
          quantity: quantity,
        );
  }

  void _remove(int index) {
    final productId = _items[index].product.id;
    setState(() => _items.removeAt(index));
    context.read<CartProvider>().removeFromSeller(
          sellerId: widget.sellerId,
          productId: productId,
        );
  }

  double get _totalAmount =>
      _items.fold(0.0, (sum, e) => sum + e.product.pricePerKg * e.quantity);

  String get _totalQuantityLabel {
    double totalKg = 0;
    double totalL = 0;
    double totalGkg = 0;
    double totalPieces = 0;

    for (final e in _items) {
      final p = e.product;
      switch (p.unitType) {
        case ProductModel.unitL:
          totalL += e.quantity;
          break;
        case ProductModel.unitG:
          totalGkg += e.quantity;
          break;
        case ProductModel.unitPiece:
          totalPieces += e.quantity;
          break;
        default:
          totalKg += e.quantity;
      }
    }

    final parts = <String>[];
    if (totalKg > 0) {
      parts.add(
          ProductModel.formatQuantityWithUnit(totalKg, ProductModel.unitKg));
    }
    if (totalL > 0) {
      parts
          .add(ProductModel.formatQuantityWithUnit(totalL, ProductModel.unitL));
    }
    if (totalGkg > 0) {
      parts.add(
          ProductModel.formatQuantityWithUnit(totalGkg, ProductModel.unitG));
    }
    if (totalPieces > 0) {
      parts.add(ProductModel.formatQuantityWithUnit(
          totalPieces, ProductModel.unitPiece));
    }
    if (parts.isEmpty) return '';
    return 'Ukupno količina: ${parts.join(' + ')}';
  }

  Future<void> _submit() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Kontakt telefon je obavezan.');
      return;
    }
    final user = context.read<AppState>().user;
    if (user == null) {
      setState(() => _error = 'Morate biti prijavljeni.');
      return;
    }
    for (final item in _items) {
      if (!item.product.isAvailable) {
        setState(() => _error = '${item.product.name} je trenutno nedostupan.');
        return;
      }
      if (item.quantity < item.product.minOrderKg) {
        setState(() => _error =
            '${item.product.name}: minimalno ${item.product.minOrderFormatted}');
        return;
      }
    }

    setState(() {
      _error = null;
      _sending = true;
    });

    try {
      final appState = context.read<AppState>();
      final isOnline = appState.isOnline;
      final note = _noteController.text.trim();
      final buyerCity = _cityController.text.trim();
      final buyerAddress = _addressController.text.trim();
      final phone = _phoneController.text.trim();

      if (isOnline) {
        final orderItems = _items
            .map((e) => OrderItemModel(
                  productId: e.product.id,
                  productName: e.product.name,
                  quantityKg: e.quantity,
                  unitType: e.product.unitType,
                  unitPrice: e.product.pricePerKg,
                ))
            .toList();

        final orderId = await OrdersService().createOrderWithItems(
          buyerId: user.id,
          sellerId: widget.sellerId,
          items: orderItems,
          note: note,
          buyerCity: buyerCity,
          buyerPhone: phone,
          buyerAddress: buyerAddress,
        );

        await ChatService().getOrCreateConversation(user.id, widget.sellerId,
            orderId: orderId);

        if (_savePhoneToProfile && (user.phone ?? '').trim() != phone) {
          await UsersService().updatePhone(user.id, phone);
          await appState.refreshUser();
        }

        if (!mounted) return;
        final cart = context.read<CartProvider>();
        await cart.clearSeller(widget.sellerId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Porudžbina je poslata prodavcu.')),
        );
      } else {
        for (final item in _items) {
          final pendingOrder = PendingOrder(
            id: 'pending_${DateTime.now().millisecondsSinceEpoch}_${item.product.id}',
            buyerId: user.id,
            sellerId: widget.sellerId,
            productId: item.product.id,
            productName: item.product.name,
            quantityKg: item.quantity,
            unitType: item.product.unitType,
            note: note,
            buyerCity: buyerCity,
            buyerAddress: buyerAddress,
            buyerPhone: phone,
            preferCall: false,
            pickupOptions: [],
            createdAt: DateTime.now(),
          );
          await appState.orderQueue.addPendingOrder(pendingOrder);
        }

        if (!mounted) return;
        final cart = context.read<CartProvider>();
        await cart.clearSeller(widget.sellerId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Porudžbine su sačuvane. Biće poslane kada je dostupan Internet.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }

      if (!mounted) return;
      context.go('/orders');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Greška: ${e.toString().split('\n').first}';
          _sending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nije moguće poslati upit.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRsd = _totalAmount.toStringAsFixed(0);
    final isOffline = context.select<AppState, bool>((s) => s.isOffline);
    final canSubmit = !_sending &&
        _items.isNotEmpty &&
        !_items.any((i) => !i.product.isAvailable);

    return Scaffold(
      appBar: AppBar(title: Text('Porudžbina kod: ${widget.sellerName}')),
      bottomNavigationBar: _items.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, -2))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ukupno:',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          '$totalRsd RSD',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: canSubmit ? _submit : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_items.any((i) => !i.product.isAvailable)
                              ? 'Nedostupno'
                              : 'Pošalji porudžbinu'),
                    ),
                  ],
                ),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tvoje odabrano',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (isOffline) ...[
                const SizedBox(height: 8),
                const OfflineReadOnlyBadge(),
              ],
              const SizedBox(height: 12),
              if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.shopping_basket_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Nema stavki. Dodaj proizvode kod prodavca.',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/seller/${widget.sellerId}'),
                        icon: const Icon(Icons.store, size: 20),
                        label: const Text('Nazad kod prodavca'),
                      ),
                    ],
                  ),
                )
              else ...[
                ...List.generate(_items.length, (i) {
                  final e = _items[i];
                  final p = e.product;
                  final step = p.quantityStep;
                  final itemTotal = (p.pricePerKg * e.quantity).toStringAsFixed(0);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.formatQuantity(e.quantity)} × ${p.priceFormatted} = $itemTotal RSD',
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Smanji količinu',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: e.quantity <= p.minOrderKg
                                    ? null
                                    : () => _setQuantity(i, e.quantity - step),
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(40, 40),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                child: Text(
                                  p.formatQuantity(e.quantity),
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Povećaj količinu',
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () =>
                                    _setQuantity(i, e.quantity + step),
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(40, 40),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Ukloni proizvod',
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red.shade400),
                                onPressed: () => _remove(i),
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(40, 40),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                if (_totalQuantityLabel.isNotEmpty)
                  Text(
                    _totalQuantityLabel,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey.shade700),
                  ),
                Text(
                  'Napomena: Cena dostave se dogovara sa domaćinom.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Podaci za dostavu',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Napomena (npr. Treba za subotu)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Grad kupca'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration:
                    const InputDecoration(labelText: 'Adresa (ulica i broj)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Kontakt telefon *'),
              ),
              Builder(
                builder: (ctx) {
                  final user = context.select<AppState, UserModel?>((s) => s.user);
                  if (user == null) return const SizedBox.shrink();
                  return CheckboxListTile(
                    value: _savePhoneToProfile,
                    onChanged: (v) =>
                        setState(() => _savePhoneToProfile = v ?? false),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Sačuvaj ovaj broj u profilu',
                      style: TextStyle(fontSize: 13),
                    ),
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_error!,
                          style: TextStyle(color: Colors.red.shade800)),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: _sending ? null : _submit,
                        child: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
