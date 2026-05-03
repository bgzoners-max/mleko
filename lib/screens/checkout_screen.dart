import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/haptic.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../models/seller_delivery_models.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import '../providers/cart_provider.dart';
import 'package:mleko/services/services.dart';

import '../widgets/app_network_image.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/skeleton.dart';

class CheckoutScreen extends StatefulWidget {
  final String productId;
  final double? initialQuantity;

  const CheckoutScreen(
      {super.key, required this.productId, this.initialQuantity});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Future<ProductModel?>? _productFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productFuture ??= context.read<ProductsService>().getProduct(widget.productId);
  }

  void _retry() => setState(() {
        _productFuture = context.read<ProductsService>().getProduct(widget.productId);
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
          return Scaffold(
            appBar: AppBar(title: const Text('Porudžbina')),
            body: const ProductDetailSkeleton(),
          );
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
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
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
      if (user.address != null && user.address!.isNotEmpty) {
        _addressController.text = user.address!;
      }
      if (user.phone != null && user.phone!.isNotEmpty) {
        _phoneController.text = user.phone!;
      }
      if (user.postalCode != null && user.postalCode!.isNotEmpty) {
        _postalCodeController.text = user.postalCode!;
      }
      _savePhoneToProfile = user.phone == null || user.phone!.isEmpty;
    }
  }

  DeliveryMethod _deliveryMethod = DeliveryMethod.courier;
  bool _sending = false;
  String? _error;

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('invalid delivery_method')) {
      return 'Izabrani način dostave privremeno nije dostupan. Pokušaj ponovo.';
    }
    if (s.contains('is currently unavailable')) {
      return 'Proizvod trenutno nije dostupan.';
    }
    if (s.contains('SocketException') || s.contains('network') || s.contains('XMLHttpRequest')) {
      return 'Nema internet veze. Proveri konekciju i pokušaj ponovo.';
    }
    return 'Porudžbina nije mogla biti poslata. Pokušaj ponovo.';
  }

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
    if (widget.product.availableKg > 0 && qty > widget.product.availableKg) {
      setState(() => _error =
          'Maksimalna dostupna količina: ${widget.product.availableFormatted}');
      return;
    }
    final missing = <String>[];
    if (_deliveryMethod == DeliveryMethod.courier) {
      if (_addressController.text.trim().isEmpty) missing.add('adresu');
      if (_cityController.text.trim().isEmpty) missing.add('grad');
      if (_postalCodeController.text.trim().isEmpty) missing.add('poštanski broj');
    }
    if (_phoneController.text.trim().isEmpty) missing.add('kontakt telefon');
    if (missing.isNotEmpty) {
      final joined = missing.length == 1
          ? missing.first
          : '${missing.sublist(0, missing.length - 1).join(', ')} i ${missing.last}';
      setState(() => _error = 'Niste uneli $joined.');
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
      final note = _noteController.text.trim();
      final buyerCity = _cityController.text.trim();
      final buyerPostalCode = _postalCodeController.text.trim();
      final buyerAddress = _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim();

      if (isOnline) {
        final ordersService = context.read<OrdersService>();
        final usersService = context.read<UsersService>();
        final chatService = context.read<ChatService>();
        final orderId = await ordersService.createSingleProductOrder(
          buyerId: user.id,
          sellerId: widget.product.sellerId,
          productId: widget.product.id,
          productName: widget.product.name,
          quantityKg: qty,
          unitType: widget.product.unitType,
          note: note,
          buyerCity: buyerCity,
          buyerPhone: phone,
          buyerAddress: buyerAddress,
          buyerPostalCode: buyerPostalCode,
          deliveryMethod: _deliveryMethod,
        );
        if (_savePhoneToProfile) {
          final shouldUpdatePhone = (user.phone ?? '').trim() != phone;
          final shouldUpdatePostalCode =
              (user.postalCode ?? '').trim() != buyerPostalCode;
          if (shouldUpdatePhone || shouldUpdatePostalCode) {
            await usersService.upsertProfile(
              user.id,
              phone: shouldUpdatePhone ? phone : null,
              postalCode: shouldUpdatePostalCode ? buyerPostalCode : null,
            );
            await appState.refreshUser();
          }
        }
        await chatService.getOrCreateConversation(
            user.id, widget.product.sellerId,
            orderId: orderId);
        AppHaptics.success();
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
          note: note,
          buyerCity: buyerCity,
          buyerAddress: buyerAddress,
          buyerPostalCode: buyerPostalCode,
          buyerPhone: phone,
          deliveryMethod: _deliveryMethod,
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
          _error = _friendlyError(e);
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
    final user = context.select<AppState, UserModel?>((s) => s.user);
    return Scaffold(
      appBar: AppBar(title: const Text('Porudžbina')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.formContentWidth(context),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: Breakpoints.horizontalPadding(context),
                right: Breakpoints.horizontalPadding(context),
                top: 24,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (widget.product.imageUrls.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppNetworkImage.thumbnail(
                              imageUrl: widget.product.imageUrls.first,
                              width: 64,
                              height: 64,
                            ),
                          )
                        else
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shopping_basket_outlined),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.product.priceFormatted,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOffline) ...[
                    const SizedBox(height: 8),
                    const OfflineReadOnlyBadge(),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                    controller: _quantityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[,.]?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText:
                          'Količina (${widget.product.quantityUnitLabel})',
                      hintText: 'Min ${widget.product.minOrderFormatted}',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Način dostave',
                      style: Theme.of(context).textTheme.titleSmall),
                  RadioGroup<DeliveryMethod>(
                    groupValue: _deliveryMethod,
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _deliveryMethod = v);
                      }
                    },
                    child: const Column(
                      children: [
                        RadioListTile<DeliveryMethod>(
                          value: DeliveryMethod.courier,
                          title: Text('Kurirska služba'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        RadioListTile<DeliveryMethod>(
                          value: DeliveryMethod.pickup,
                          title: Text('Lično preuzimanje'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_deliveryMethod == DeliveryMethod.courier) ...[
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Adresa (ulica i broj)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityController,
                      decoration:
                          const InputDecoration(labelText: 'Grad'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _postalCodeController,
                      decoration: const InputDecoration(labelText: 'Poštanski broj'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Dogovori se sa prodavcem o mestu i vremenu preuzimanja.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Kontakt telefon *'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Napomena (npr. Treba za subotu)'),
                  ),
                  const SizedBox(height: 4),
                  if (user != null)
                    CheckboxListTile(
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
                    ),
                  const SizedBox(height: 8),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (_sending || !widget.product.isAvailable)
                        ? null
                        : _submit,
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
        ),
      ),
    );
  }
}
