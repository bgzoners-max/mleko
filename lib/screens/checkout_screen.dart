import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import '../providers/cart_provider.dart';
import 'package:mleko/services/services.dart';

import '../widgets/app_error_retry.dart';
import '../widgets/offline_indicator.dart';

class CheckoutScreen extends StatefulWidget {
  final String productId;
  final double? initialQuantity;

  const CheckoutScreen(
      {super.key, required this.productId, this.initialQuantity});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Future<ProductModel?> _productFuture =
      ProductsService().getProduct(widget.productId);

  void _retry() => setState(() {
        _productFuture = ProductsService().getProduct(widget.productId);
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductModel?>(
      future: _productFuture,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Porudžbina')),
            body: AppErrorRetry(
              message: 'Greška pri učitavanju proizvoda.',
              detail: snap.error?.toString(),
              onRetry: _retry,
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final product = snap.data;
        if (product == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Proizvod nije pronađen.')));
        }
        return _CheckoutForm(
            product: product, initialQuantity: widget.initialQuantity);
      },
    );
  }
}

class _CheckoutForm extends StatefulWidget {
  final ProductModel product;
  final double? initialQuantity;

  const _CheckoutForm({required this.product, this.initialQuantity});

  @override
  State<_CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends State<_CheckoutForm> {
  late final TextEditingController _quantityController;
  final _noteController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _savePhoneToProfile = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuantity ?? 1.0;
    _quantityController = TextEditingController(
      text: initial
          .toStringAsFixed(initial.truncateToDouble() == initial ? 0 : 1),
    );
    final user = context.read<AppState>().user;
    if (user != null) {
      if (user.city != null && user.city!.isNotEmpty) {
        _cityController.text = user.city!;
      }
      if (user.phone != null && user.phone!.isNotEmpty) {
        _phoneController.text = user.phone!;
      }
      _savePhoneToProfile = user.phone == null || user.phone!.isEmpty;
    }
  }

  bool _sending = false;
  String? _error;

  Future<void> _submit() async {
    if (!widget.product.isAvailable) {
      setState(() => _error = 'Proizvod je trenutno nedostupan.');
      return;
    }
    final qty = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    if (qty == null || qty < widget.product.minOrderKg) {
      setState(() =>
          _error = 'Minimalna porudžbina: ${widget.product.minOrderFormatted}');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Kontakt telefon je obavezan.');
      return;
    }
    final user = context.read<AppState>().user;
    if (user == null) {
      setState(() => _error = 'Morate biti prijavljeni.');
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    try {
      final appState = context.read<AppState>();
      final isOnline = appState.isOnline;
      final phone = _phoneController.text.trim();

      if (isOnline) {
        // Online mode: Send order to server
        final order = OrderModel(
          id: '',
          buyerId: user.id,
          sellerId: widget.product.sellerId,
          productId: widget.product.id,
          productName: widget.product.name,
          quantityKg: qty,
          unitType: widget.product.unitType,
          note: _noteController.text.trim(),
          buyerCity: _cityController.text.trim(),
          buyerPhone: phone,
          buyerAddress: user.address,
          status: OrderStatus.sent,
          createdAt: DateTime.now(),
        );
        final orderId = await OrdersService().createOrder(order);
        if (_savePhoneToProfile && (user.phone ?? '').trim() != phone) {
          await UsersService().updatePhone(user.id, phone);
          await appState.refreshUser();
        }
        await ChatService().getOrCreateConversation(
            user.id, widget.product.sellerId,
            orderId: orderId);
        if (!mounted) return;
        await context.read<CartProvider>().removeFromSeller(
              sellerId: widget.product.sellerId,
              productId: widget.product.id,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upit je poslat prodavcu.')));
      } else {
        // Offline mode: Queue order for later sync
        final pendingOrder = PendingOrder(
          id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
          buyerId: user.id,
          sellerId: widget.product.sellerId,
          productId: widget.product.id,
          productName: widget.product.name,
          quantityKg: qty,
          unitType: widget.product.unitType,
          note: _noteController.text.trim(),
          buyerCity: _cityController.text.trim(),
          buyerAddress: user.address ?? _cityController.text.trim(),
          buyerPhone: phone,
          preferCall: false,
          pickupOptions: [],
          createdAt: DateTime.now(),
        );
        await appState.orderQueue.addPendingOrder(pendingOrder);
        if (!mounted) return;
        await context.read<CartProvider>().removeFromSeller(
              sellerId: widget.product.sellerId,
              productId: widget.product.id,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Porudžbina je sačuvana. Biće poslata kada je dostupan Internet.'),
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
    final isOffline = context.select<AppState, bool>((s) => s.isOffline);
    return Scaffold(
      appBar: AppBar(title: const Text('Porudžbina')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${widget.product.name} – ${widget.product.priceFormatted}',
                  style: Theme.of(context).textTheme.titleMedium),
              if (isOffline) ...[
                const SizedBox(height: 8),
                const OfflineReadOnlyBadge(),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Količina (${widget.product.quantityUnitLabel})',
                  hintText: 'Min ${widget.product.minOrderFormatted}',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Napomena (npr. Treba za subotu)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Grad kupca'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Kontakt telefon *'),
              ),
              const SizedBox(height: 4),
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
              const SizedBox(height: 8),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    (_sending || !widget.product.isAvailable) ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.product.isAvailable
                        ? 'Pošalji upit prodavcu'
                        : 'Nedostupno'),
              ),
              const SizedBox(height: 12),
              Text(
                'Ništa se ne naplaćuje u aplikaciji – dogovor, isporuka i plaćanje direktno sa proizvođačem.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

