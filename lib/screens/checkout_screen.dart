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
import '../utils/number_input_utils.dart';
import '../utils/quantity_engine.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/checkout/checkout_product_summary_card.dart';
import '../widgets/checkout/checkout_single_buyer_form.dart';
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
    _productFuture ??=
        context.read<ProductsService>().getProduct(widget.productId);
  }

  void _retry() => setState(() {
        _productFuture =
            context.read<ProductsService>().getProduct(widget.productId);
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
            appBar: AppBar(title: const Text('Porudžbina')),
            body: const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Proizvod nije pronađen',
              subtitle: 'Ovaj proizvod više nije dostupan ili je uklonjen.',
            ),
          );
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

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
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
    if (s.contains('SocketException') ||
        s.contains('network') ||
        s.contains('XMLHttpRequest')) {
      return 'Nema internet veze. Proveri konekciju i pokušaj ponovo.';
    }
    return 'Porudžbina nije mogla biti poslata. Pokušaj ponovo.';
  }

  Future<void> _submit() async {
    if (!widget.product.isAvailable) {
      setState(() => _error = 'Proizvod je trenutno nedostupan.');
      return;
    }
    final qty = NumberInputUtils.parseDecimal(_quantityController.text);
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
    final step = widget.product.quantityStep;
    final normalizedUnit = widget.product.unitType == ProductModel.unitG
        ? ProductModel.unitKg
        : widget.product.unitType;
    if (!QuantityEngine.isValidQuantity(
      quantity: qty,
      minQuantity: widget.product.minOrderKg,
      step: step,
    )) {
      setState(() => _error =
          'Količina mora biti od minimuma i u koracima od ${ProductModel.formatQuantityWithUnit(step, normalizedUnit)}.');
      return;
    }
    final missing = <String>[];
    if (_deliveryMethod == DeliveryMethod.courier) {
      if (_addressController.text.trim().isEmpty) {
        missing.add('adresu');
      }
      if (_cityController.text.trim().isEmpty) {
        missing.add('grad');
      }
      if (_postalCodeController.text.trim().isEmpty) {
        missing.add('poštanski broj');
      }
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
                  CheckoutProductSummaryCard(
                    product: widget.product,
                    isOffline: isOffline,
                  ),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nakon slanja upita, prodavac će dobiti vaše podatke i kontaktirati vas o daljem dogovoru.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      height: 1.4,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckoutSingleBuyerForm(
                    deliveryMethod: _deliveryMethod,
                    onDeliveryMethodChanged: (m) =>
                        setState(() => _deliveryMethod = m),
                    addressController: _addressController,
                    cityController: _cityController,
                    postalCodeController: _postalCodeController,
                    phoneController: _phoneController,
                    noteController: _noteController,
                    showSavePhone: user != null,
                    savePhoneToProfile: _savePhoneToProfile,
                    onSavePhoneChanged: (val) =>
                        setState(() => _savePhoneToProfile = val),
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
