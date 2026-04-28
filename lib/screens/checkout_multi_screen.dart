import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_item_model.dart';
import '../models/seller_delivery_models.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import '../providers/cart_provider.dart';
import 'package:mleko/services/services.dart';
import '../models/product_model.dart';

import '../widgets/offline_indicator.dart';
import '../widgets/skeleton.dart';

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
    final productsService = context.read<ProductsService>();
    // Batch load umesto N+1 petlje
    final products =
        await productsService.getProductsByIds(productQuantities.keys.toList());
    final items = <({ProductModel product, double quantity})>[];
    for (final e in productQuantities.entries) {
      final p = products[e.key];
      if (p != null && p.sellerId == widget.sellerId) {
        items.add((product: p, quantity: e.value));
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
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Porudžbina')),
        body: const ProductDetailSkeleton(),
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
  final _postalCodeController = TextEditingController();
  bool _sending = false;
  String? _error;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _savePhoneToProfile = false;
  bool _deliveryLoading = true;
  List<SellerDeliveryPointModel> _allDeliveryPoints = const [];
  List<SellerDeliveryPointModel> _deliveryPoints = const [];
  String? _deliveryRestrictionMessage;
  DeliveryMethod _deliveryMethod = DeliveryMethod.courier;
  String? _selectedDeliveryCity;
  SellerDeliveryPointModel? _selectedDeliveryPoint;
  SellerDeliverySlotModel? _selectedDeliverySlot;

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
      if (user.postalCode != null && user.postalCode!.isNotEmpty) {
        _postalCodeController.text = user.postalCode!;
      }
      _savePhoneToProfile = user.phone == null || user.phone!.isEmpty;
    }
    _loadDeliveryOptions();
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
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryOptions() async {
    try {
      final points = await SellerDeliveryService()
          .getSellerDeliveryPoints(widget.sellerId, onlyActive: true);
      if (!mounted) return;
      setState(() {
        _allDeliveryPoints = points;
        _deliveryLoading = false;
      });
      _refreshDeliveryAvailability();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allDeliveryPoints = const [];
        _deliveryPoints = const [];
        _deliveryLoading = false;
        _deliveryRestrictionMessage = null;
      });
    }
  }

  Set<String> _allowedDeliveryPointIds() {
    final allPointIds = _allDeliveryPoints.map((point) => point.id).toSet();
    Set<String>? allowed;

    for (final item in _items) {
      switch (item.product.deliveryMode) {
        case ProductDeliveryMode.none:
          return <String>{};
        case ProductDeliveryMode.allSellerPoints:
          continue;
        case ProductDeliveryMode.selectedPoints:
          // Uzimamo u obzir samo one lokacije koje su i dalje aktivne za prodavca
          final ids = item.product.selectedDeliveryPointIds
              .toSet()
              .intersection(allPointIds);
          if (ids.isEmpty) return <String>{};
          allowed = allowed == null ? ids : allowed.intersection(ids);
      }
    }

    return allowed ?? allPointIds;
  }

  String? _buildDeliveryRestrictionMessage(Set<String> allowedIds) {
    if (_items
        .any((item) => item.product.deliveryMode == ProductDeliveryMode.none)) {
      return _items.length == 1
          ? 'Ovaj proizvod ne podržava ličnu dostavu domaćina.'
          : 'Bar jedan proizvod ne podržava ličnu dostavu domaćina.';
    }
    if (_allDeliveryPoints.isNotEmpty && allowedIds.isEmpty) {
      return _items.length == 1
          ? 'Ovaj proizvod trenutno nema aktivnih lokacija za ličnu dostavu.'
          : 'Odabrani proizvodi nemaju zajedničku lokaciju za ličnu dostavu.';
    }
    return null;
  }

  void _refreshDeliveryAvailability() {
    final allowedIds = _allowedDeliveryPointIds();
    final filteredPoints = _allDeliveryPoints
        .where((point) => allowedIds.contains(point.id))
        .toList(growable: false);
    final restrictionMessage = _buildDeliveryRestrictionMessage(allowedIds);

    String? nextCity = _selectedDeliveryCity;
    SellerDeliveryPointModel? nextPoint = _selectedDeliveryPoint;
    SellerDeliverySlotModel? nextSlot = _selectedDeliverySlot;

    if (filteredPoints.isEmpty) {
      nextCity = null;
      nextPoint = null;
      nextSlot = null;
    } else {
      final availableCities = filteredPoints.map((point) => point.city).toSet();
      if (nextCity == null || !availableCities.contains(nextCity)) {
        nextCity = filteredPoints.first.city;
      }

      final cityPoints = filteredPoints
          .where((point) => point.city == nextCity)
          .toList(growable: false);

      if (nextPoint == null ||
          !cityPoints.any((point) => point.id == nextPoint!.id)) {
        nextPoint =
            cityPoints.isNotEmpty ? cityPoints.first : filteredPoints.first;
      }

      final activeSlots = nextPoint.activeSlots;
      if (nextSlot == null ||
          !activeSlots.any((slot) => slot.id == nextSlot!.id)) {
        nextSlot = activeSlots.isNotEmpty ? activeSlots.first : null;
      }
    }

    setState(() {
      _deliveryPoints = filteredPoints;
      _deliveryRestrictionMessage = restrictionMessage;
      _selectedDeliveryCity = nextCity;
      _selectedDeliveryPoint = nextPoint;
      _selectedDeliverySlot = nextSlot;
      if (filteredPoints.isEmpty) {
        _deliveryMethod = DeliveryMethod.agreement;
      }
      if (_deliveryMethod == DeliveryMethod.sellerDelivery &&
          nextCity != null) {
        _cityController.text = nextCity;
      }
    });
  }

  bool get _hasSellerDeliveryOptions => _deliveryPoints.isNotEmpty;

  List<String> get _deliveryCities {
    final seen = <String>{};
    final result = <String>[];
    for (final point in _deliveryPoints) {
      if (seen.add(point.city)) {
        result.add(point.city);
      }
    }
    return result;
  }

  List<SellerDeliveryPointModel> get _pointsForSelectedCity {
    final city = _selectedDeliveryCity;
    if (city == null) return const [];
    return _deliveryPoints
        .where((point) => point.city == city)
        .toList(growable: false);
  }

  DeliverySelectionModel? get _deliverySelection {
    if (_deliveryMethod != DeliveryMethod.sellerDelivery ||
        _selectedDeliveryPoint == null ||
        _selectedDeliverySlot == null) {
      return null;
    }
    return DeliverySelectionModel.fromPointAndSlot(
      _selectedDeliveryPoint!,
      _selectedDeliverySlot!,
    );
  }

  void _selectDeliveryCity(String? city) {
    if (city == null) return;
    final points =
        _deliveryPoints.where((point) => point.city == city).toList();
    final point = points.isNotEmpty ? points.first : null;
    final slot = point != null && point.activeSlots.isNotEmpty
        ? point.activeSlots.first
        : null;
    setState(() {
      _selectedDeliveryCity = city;
      _selectedDeliveryPoint = point;
      _selectedDeliverySlot = slot;
      _cityController.text = city;
    });
  }

  void _selectDeliveryPoint(String? pointId) {
    if (pointId == null) return;
    final point = _pointsForSelectedCity.firstWhere(
      (entry) => entry.id == pointId,
    );
    setState(() {
      _selectedDeliveryPoint = point;
      _selectedDeliverySlot =
          point.activeSlots.isNotEmpty ? point.activeSlots.first : null;
      _cityController.text = point.city;
    });
  }

  void _selectDeliverySlot(String? slotId) {
    if (slotId == null || _selectedDeliveryPoint == null) return;
    final slot = _selectedDeliveryPoint!.activeSlots.firstWhere(
      (entry) => entry.id == slotId,
    );
    setState(() => _selectedDeliverySlot = slot);
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
    final removedItem = _items[index];
    final productId = removedItem.product.id;

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(context, removedItem, animation),
      duration: const Duration(milliseconds: 300),
    );

    setState(() => _items.removeAt(index));
    context.read<CartProvider>().removeFromSeller(
          sellerId: widget.sellerId,
          productId: productId,
        );
    _refreshDeliveryAvailability();
  }

  Widget _buildItem(BuildContext context,
      ({ProductModel product, double quantity}) item, Animation<double> animation) {
    final theme = Theme.of(context);
    final p = item.product;
    final index = _items.indexWhere((e) => e.product.id == p.id);
    // Ako je index -1, znači da gradimo item koji se upravo uklanja
    final actualIndex = index;

    final step = p.quantityStep;
    final itemTotal = (p.pricePerKg * item.quantity).toStringAsFixed(0);

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
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
                        '${p.formatQuantity(item.quantity)} × ${p.priceFormatted} = $itemTotal RSD',
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
                      onPressed: actualIndex == -1 || item.quantity <= p.minOrderKg
                          ? null
                          : () => _setQuantity(actualIndex, item.quantity - step),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        p.formatQuantity(item.quantity),
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Povećaj količinu',
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: actualIndex == -1
                          ? null
                          : () => _setQuantity(actualIndex, item.quantity + step),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ukloni proizvod',
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade400),
                      onPressed: actualIndex == -1 ? null : () => _remove(actualIndex),
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
        ),
      ),
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

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('invalid delivery_method')) {
      return 'Izabrani način dostave privremeno nije dostupan. Pokušaj ponovo.';
    }
    if (s.contains('is currently unavailable')) {
      return 'Jedan od proizvoda trenutno nije dostupan.';
    }
    if (s.contains('below min_order')) {
      return 'Količina je ispod minimalne porudžbine za jedan od proizvoda.';
    }
    if (s.contains('below delivery slot minimum')) {
      return 'Ukupan iznos nije dostigao minimum za izabrani termin dostave.';
    }
    if (s.contains('SocketException') ||
        s.contains('network') ||
        s.contains('XMLHttpRequest')) {
      return 'Nema internet veze. Proveri konekciju i pokušaj ponovo.';
    }
    return 'Porudžbina nije mogla biti poslata. Pokušaj ponovo.';
  }

  String _missingFieldsError(List<String> fields) {
    if (fields.length == 1) return 'Niste uneli ${fields.first}.';
    final all =
        '${fields.sublist(0, fields.length - 1).join(', ')} i ${fields.last}';
    return 'Niste uneli $all.';
  }

  Future<void> _submit() async {
    final missing = <String>[];
    if (_deliveryMethod == DeliveryMethod.courier) {
      if (_addressController.text.trim().isEmpty) missing.add('adresu');
      if (_cityController.text.trim().isEmpty) missing.add('grad');
    }
    if (_phoneController.text.trim().isEmpty) missing.add('kontakt telefon');
    if (missing.isNotEmpty) {
      setState(() => _error = _missingFieldsError(missing));
      return;
    }
    if (_deliveryMethod == DeliveryMethod.sellerDelivery &&
        _deliverySelection == null) {
      setState(() => _error =
          'Izaberi grad, lokaciju i termin za ličnu dostavu domaćina.');
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

    final appState = context.read<AppState>();
    final ordersService = context.read<OrdersService>();
    final chatService = context.read<ChatService>();
    final usersService = context.read<UsersService>();
    final isOnline = appState.isOnline;
    final note = _noteController.text.trim();
    final buyerCity = _deliveryMethod == DeliveryMethod.sellerDelivery
        ? (_selectedDeliveryCity ?? _cityController.text.trim())
        : _cityController.text.trim();
    final buyerAddress = _addressController.text.trim();
    final buyerPostalCode = _postalCodeController.text.trim();
    final phone = _phoneController.text.trim();
    final deliverySelection = _deliverySelection;

    // 🚀 NOVI SISTEM: Vraća true za online uspeh, false za offline uspeh, ili hvata grešku
    final result = await ErrorHandlerService().executeWithResult<bool>(
      'Submit Order',
      () async {
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

          final orderId = await ordersService.createOrderWithItems(
            buyerId: user.id,
            sellerId: widget.sellerId,
            items: orderItems,
            note: note,
            buyerCity: buyerCity,
            buyerPhone: phone,
            buyerAddress: buyerAddress,
            buyerPostalCode: buyerPostalCode,
            deliveryMethod: _deliveryMethod,
            deliverySelection: deliverySelection,
          );

          await chatService.getOrCreateConversation(user.id, widget.sellerId,
              orderId: orderId);

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

          if (!mounted) return false;
          final cart = context.read<CartProvider>();
          await cart.clearSeller(widget.sellerId);
          return true; // Online
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
              buyerPostalCode: buyerPostalCode,
              buyerPhone: phone,
              deliveryMethod: _deliveryMethod,
              deliveryCity: deliverySelection?.city,
              deliveryPointId: deliverySelection?.pointId,
              deliverySlotId: deliverySelection?.slotId,
              deliveryPointLabel: deliverySelection?.pointLabel,
              deliveryAddress: deliverySelection?.address,
              deliveryWeekday: deliverySelection?.weekday,
              deliveryTimeFrom: deliverySelection?.timeFrom,
              deliveryTimeTo: deliverySelection?.timeTo,
              deliveryFeeRsd: deliverySelection?.deliveryFeeRsd,
              minOrderAmountRsd: deliverySelection?.minOrderAmountRsd,
              preferCall: false,
              pickupOptions: [],
              createdAt: DateTime.now(),
            );
            await appState.orderQueue.addPendingOrder(pendingOrder);
          }

          if (!mounted) return false;
          final cart = context.read<CartProvider>();
          await cart.clearSeller(widget.sellerId);
          return false; // Offline
        }
      },
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.data == true
              ? 'Porudžbina je poslata prodavcu.'
              : 'Porudžbine su sačuvane. Biće poslane kada je dostupan Internet.'),
          backgroundColor: result.data == true ? null : Colors.orange,
          duration: result.data == true
              ? const Duration(seconds: 2)
              : const Duration(seconds: 4),
        ),
      );
      context.go('/orders');
    } else {
      setState(() {
        // Koristi staru dobru _friendlyError funkciju da ne izgubimo specifične "min_order" poruke
        _error =
            _friendlyError(result.error?.originalException ?? result.error!);
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRsd = _totalAmount.toStringAsFixed(0);
    final isOffline = context.select<AppState, bool>((s) => s.isOffline);
    final user = context.select<AppState, UserModel?>((s) => s.user);
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SafeArea(
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
                    AnimatedList(
                      key: _listKey,
                      initialItemCount: _items.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index, animation) {
                        return _buildItem(context, _items[index], animation);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (_totalQuantityLabel.isNotEmpty)
                      Text(
                        _totalQuantityLabel,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade700),
                      ),
                    Text(
                      _hasSellerDeliveryOptions
                          ? 'Prodavac nudi i ličnu dostavu na izabranim lokacijama i terminima.'
                          : 'Napomena: Cena dostave se dogovara sa domaćinom.',
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
                  if (!_deliveryLoading &&
                      !_hasSellerDeliveryOptions &&
                      _deliveryRestrictionMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _deliveryRestrictionMessage!,
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Način dostave',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  // ignore: deprecated_member_use
                  RadioListTile<DeliveryMethod>(
                    value: DeliveryMethod.courier,
                    // ignore: deprecated_member_use
                    groupValue: _deliveryMethod,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Kurirska služba'),
                    subtitle: const Text(
                        'Dostava na adresu putem kurira (npr. Post Express, D Express)'),
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _deliveryMethod = value);
                    },
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<DeliveryMethod>(
                    value: DeliveryMethod.pickup,
                    // ignore: deprecated_member_use
                    groupValue: _deliveryMethod,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lično preuzimanje'),
                    subtitle: const Text(
                        'Preuzimanje na dogovorenoj lokaciji kod prodavca'),
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _deliveryMethod = value);
                    },
                  ),
                  if (_deliveryLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ] else if (_hasSellerDeliveryOptions) ...[
                    // ignore: deprecated_member_use
                    RadioListTile<DeliveryMethod>(
                      value: DeliveryMethod.sellerDelivery,
                      // ignore: deprecated_member_use
                      groupValue: _deliveryMethod,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dostava od strane prodavca'),
                      subtitle: const Text(
                          'Prodavac lično dostavlja na definisane lokacije i termine'),
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _deliveryMethod = value;
                          if (_selectedDeliveryCity != null) {
                            _cityController.text = _selectedDeliveryCity!;
                          }
                        });
                      },
                    ),
                    if (_deliveryRestrictionMessage != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _deliveryRestrictionMessage!,
                          style: TextStyle(
                              color: Colors.orange.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                    if (_deliveryMethod == DeliveryMethod.sellerDelivery) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDeliveryCity,
                        decoration: const InputDecoration(labelText: 'Grad'),
                        items: _deliveryCities
                            .map(
                              (city) => DropdownMenuItem<String>(
                                value: city,
                                child: Text(city),
                              ),
                            )
                            .toList(),
                        onChanged: _selectDeliveryCity,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDeliveryPoint?.id,
                        decoration:
                            const InputDecoration(labelText: 'Lokacija'),
                        items: _pointsForSelectedCity
                            .map(
                              (point) => DropdownMenuItem<String>(
                                value: point.id,
                                child: Text(point.summaryLabel),
                              ),
                            )
                            .toList(),
                        onChanged: _selectDeliveryPoint,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDeliverySlot?.id,
                        decoration: const InputDecoration(labelText: 'Termin'),
                        items: (_selectedDeliveryPoint?.activeSlots ?? const [])
                            .map(
                              (slot) => DropdownMenuItem<String>(
                                value: slot.id,
                                child: Text(
                                  '${slot.weekdayLabel}, ${slot.timeRangeLabel}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _selectDeliverySlot,
                      ),
                      if (_deliverySelection != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _deliverySelection!.scheduleLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_deliverySelection!.pointLabel}, ${_deliverySelection!.address}',
                              ),
                              if (_deliverySelection!.feeLabel != null)
                                Text(
                                    'Dostava: ${_deliverySelection!.feeLabel}'),
                              if (_deliverySelection!.minOrderLabel != null)
                                Text(
                                  'Minimum za termin: ${_deliverySelection!.minOrderLabel}',
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                  const SizedBox(height: 12),
                  if (_deliveryMethod == DeliveryMethod.courier) ...[
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Adresa (ulica i broj)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Grad'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Poštanski broj'),
                    ),
                    const SizedBox(height: 12),
                  ] else if (_deliveryMethod == DeliveryMethod.pickup) ...[
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
                          const SizedBox(width: 10),
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
                  ] else if (_deliveryMethod ==
                      DeliveryMethod.sellerDelivery) ...[
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Napomena za preuzimanje (opciono)'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Kontakt telefon *'),
                  ),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Napomena (npr. Treba za subotu)'),
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
        ),
      ),
    );
  }
}
