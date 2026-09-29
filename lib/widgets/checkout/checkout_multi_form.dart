import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../models/order_item_model.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../models/seller_delivery_models.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';
import '../../utils/quantity_engine.dart';
import 'package:mleko/services/services.dart';
import '../../services/core/analytics_service.dart';
import 'dart:async';
import '../offline_indicator.dart';
import 'checkout_address_form.dart';
import 'checkout_bottom_nav.dart';
import 'checkout_delivery_options.dart';
import 'checkout_item_card.dart';

class CheckoutMultiForm extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final List<({ProductModel product, double quantity})> items;

  const CheckoutMultiForm({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.items,
  });

  @override
  State<CheckoutMultiForm> createState() => _CheckoutMultiFormState();
}

class _CheckoutMultiFormState extends State<CheckoutMultiForm> {
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
    unawaited(AnalyticsService().logBeginCheckout(_items.length, _totalAmount));
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
  void didUpdateWidget(covariant CheckoutMultiForm oldWidget) {
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
    AppHaptics.selection();
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
      (context, animation) => CheckoutItemCard(
        item: removedItem,
        animation: animation,
        isRemoving: true,
      ),
      duration: const Duration(milliseconds: 300),
    );

    setState(() => _items.removeAt(index));
    context.read<CartProvider>().removeFromSeller(
          sellerId: widget.sellerId,
          productId: productId,
        );
    _refreshDeliveryAvailability();
  }

  double get _totalAmount =>
      _items.fold(0.0, (sum, e) => sum + e.product.pricePerKg * e.quantity);

  String get _totalQuantityLabel {
    double totalKg = 0;
    double totalL = 0;
    double totalGkg = 0;
    double totalPieces = 0;
    double totalVeza = 0;
    double totalPak = 0;

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
        case ProductModel.unitVeza:
          totalVeza += e.quantity;
          break;
        case ProductModel.unitPak:
          totalPak += e.quantity;
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
    if (totalVeza > 0) {
      parts.add(ProductModel.formatQuantityWithUnit(
          totalVeza, ProductModel.unitVeza));
    }
    if (totalPak > 0) {
      parts.add(ProductModel.formatQuantityWithUnit(
          totalPak, ProductModel.unitPak));
    }
    if (parts.isEmpty) return '';
    return 'Ukupno količina: ${parts.join(' + ')}';
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('seller cannot buy own products')) {
      return 'Nije moguće poručiti sopstvene proizvode.';
    }
    if (s.contains('must follow order step')) {
      return 'Količina mora biti usklađena sa korakom porudžbine za izabrani proizvod.';
    }
    if (s.contains('exceeds available stock')) {
      return 'Izabrana količina prevazilazi trenutno dostupnu zalihu.';
    }
    if (s.contains('honey products must use kg unit')) {
      return 'Med se može poručiti samo u kilogramima.';
    }
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
      if (!QuantityEngine.isProductQuantityValid(
        quantity: item.quantity,
        minOrderKg: item.product.minOrderKg,
        orderStep: item.product.orderStep,
      )) {
        final step = QuantityEngine.resolveStep(
          orderStep: item.product.orderStep,
          minQuantity: item.product.minOrderKg,
        );
        setState(() => _error =
            '${item.product.name}: količina mora pratiti korak (${item.product.formatQuantity(step)}).');
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
          unawaited(AnalyticsService().logPurchase(
            transactionId: orderId,
            value: _totalAmount,
            itemCount: _items.length,
          ));
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
      unawaited(AppHaptics.success());
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
    final isOffline = context.select<AppState, bool>((s) => s.isOffline);
    final user = context.select<AppState, UserModel?>((s) => s.user);
    final totalRsd = _totalAmount.toStringAsFixed(0);
    final canSubmit = !_sending &&
        _items.isNotEmpty &&
        !_items.any((i) => !i.product.isAvailable);

    return Scaffold(
      appBar: AppBar(title: Text('Porudžbina kod: ${widget.sellerName}')),
      bottomNavigationBar: CheckoutBottomNav(
        isEmpty: _items.isEmpty,
        totalRsd: totalRsd,
        canSubmit: canSubmit,
        sending: _sending,
        hasUnavailableItems: _items.any((i) => !i.product.isAvailable),
        onSubmit: _submit,
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
                        return CheckoutItemCard(
                          item: _items[index],
                          animation: animation,
                          onQuantityChanged: (q) => _setQuantity(index, q),
                          onRemove: () => _remove(index),
                        );
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
                  CheckoutDeliveryOptions(
                    deliveryLoading: _deliveryLoading,
                    hasSellerDeliveryOptions: _hasSellerDeliveryOptions,
                    deliveryRestrictionMessage: _deliveryRestrictionMessage,
                    deliveryMethod: _deliveryMethod,
                    onDeliveryMethodChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _deliveryMethod = val;
                          if (_deliveryMethod == DeliveryMethod.sellerDelivery &&
                              _selectedDeliveryCity != null) {
                            _cityController.text = _selectedDeliveryCity!;
                          }
                        });
                      }
                    },
                    deliveryCities: _deliveryCities,
                    selectedDeliveryCity: _selectedDeliveryCity,
                    onCityChanged: _selectDeliveryCity,
                    pointsForSelectedCity: _pointsForSelectedCity,
                    selectedDeliveryPointId: _selectedDeliveryPoint?.id,
                    onPointChanged: _selectDeliveryPoint,
                    selectedDeliveryPoint: _selectedDeliveryPoint,
                    selectedDeliverySlotId: _selectedDeliverySlot?.id,
                    onSlotChanged: _selectDeliverySlot,
                    deliverySelection: _deliverySelection,
                  ),
                  const SizedBox(height: 12),
                  CheckoutAddressForm(
                    deliveryMethod: _deliveryMethod,
                    addressController: _addressController,
                    cityController: _cityController,
                    postalCodeController: _postalCodeController,
                    phoneController: _phoneController,
                    noteController: _noteController,
                    savePhoneToProfile: _savePhoneToProfile,
                    onSavePhoneChanged: (v) => setState(() => _savePhoneToProfile = v ?? false),
                    isUserLoggedIn: user != null,
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
