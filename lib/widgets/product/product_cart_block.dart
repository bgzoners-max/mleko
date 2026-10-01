import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
import '../../core/haptic.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';
import '../../services/core/analytics_service.dart';
import '../../services/services.dart';
import '../../utils/quantity_engine.dart';
import '../bounce_tap_button.dart';
import 'seller_inline_cart_section.dart';

class ProductCartBlock extends StatefulWidget {
  final ProductModel product;
  final bool desktopMode;

  const ProductCartBlock({
    super.key,
    required this.product,
    this.desktopMode = false,
  });

  @override
  State<ProductCartBlock> createState() => _ProductCartBlockState();
}

class _ProductCartBlockState extends State<ProductCartBlock> {
  late double _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.minOrderKg > 0 ? widget.product.minOrderKg : 1.0;
  }

  @override
  void didUpdateWidget(covariant ProductCartBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.product.minOrderKg != widget.product.minOrderKg) {
      _quantity =
          widget.product.minOrderKg > 0 ? widget.product.minOrderKg : 1.0;
    }
  }

  Future<void> _addToCart() async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registruj se ili se prijavi da bi poslao porudžbinu.'),
        ),
      );
      context.go('/login');
      return;
    }

    final cart = context.read<CartProvider>();
    final result = await ErrorHandlerService().executeWithResult(
      'Add to cart',
      () => cart.addForSeller(
        sellerId: widget.product.sellerId,
        productId: widget.product.id,
        quantity: _quantity,
      ),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      unawaited(AnalyticsService().logAddToCart(widget.product, _quantity));
      final isWideLayout = MediaQuery.of(context).size.width >= 800;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dodato u korpu (${widget.product.formatQuantity(_quantity)}).',
          ),
          action: SnackBarAction(
            label: 'Pregled',
            onPressed: () =>
                context.push('/checkout-seller/${widget.product.sellerId}'),
          ),
          behavior:
              isWideLayout ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
          margin: isWideLayout
              ? EdgeInsets.only(
                  bottom: 16,
                  right: 16,
                  left: MediaQuery.of(context).size.width - 400 - 16,
                )
              : null,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.error?.getUserMessage() ?? 'Greška pri dodavanju u korpu.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openChat() async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      unawaited(context.push('/login'));
      return;
    }
    if (user.id == widget.product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ovo je vaš proizvod.')),
      );
      return;
    }
    try {
      final convId = await context
          .read<ChatService>()
          .getOrCreateConversation(user.id, widget.product.sellerId);
      if (mounted) unawaited(context.push('/chat/$convId'));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nije moguće otvoriti ćaskanje.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product;
    final totalPrice = _quantity * product.pricePerKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (product.isAvailable)
          Row(
            children: [
              _ProductQuantityStepper(
                quantity: _quantity,
                minQuantity: product.minOrderKg,
                maxQuantity: product.maxOrderQuantity,
                step: product.quantityStep,
                formattedQuantity: product.formatQuantity(_quantity),
                onChanged: (newQuantity) =>
                    setState(() => _quantity = newQuantity),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: BounceTapButton(
                    onPressed: () =>
                        withHaptic(() => _addToCart(), medium: true),
                    builder: (onPressed) => ElevatedButton.icon(
                      onPressed: onPressed,
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: Text(
                        'Dodaj u korpu (${totalPrice.toStringAsFixed(0)} RSD)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AmazonColors.amberLight,
                        foregroundColor: AmazonColors.darkNavy,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: AmazonColors.amberDark,
                            width: 0.9,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AmazonColors.darkCard : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Trenutno nedostupno za naručivanje',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        const SizedBox(height: 8),
        _SellerChatPrompt(
          sellerId: product.sellerId,
          onTap: _openChat,
        ),
        const SizedBox(height: 8),
        SellerInlineCartSection(sellerId: product.sellerId),
      ],
    );
  }
}

class _ProductQuantityStepper extends StatelessWidget {
  final double quantity;
  final double minQuantity;
  final double maxQuantity;
  final double step;
  final String formattedQuantity;
  final ValueChanged<double> onChanged;

  const _ProductQuantityStepper({
    required this.quantity,
    required this.minQuantity,
    required this.maxQuantity,
    required this.step,
    required this.formattedQuantity,
    required this.onChanged,
  });

  void _decrease() {
    final next = quantity - step;
    final normalized = next < minQuantity
        ? minQuantity
        : QuantityEngine.normalizeQuantity(
            quantity: next,
            minQuantity: minQuantity,
            step: step,
          );
    onChanged(normalized);
  }

  void _increase() {
    final next = quantity + step;
    final normalized = next > maxQuantity
        ? maxQuantity
        : QuantityEngine.normalizeQuantity(
            quantity: next,
            minQuantity: minQuantity,
            step: step,
          );
    onChanged(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : const Color(0xFFF7F8F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 46),
            onPressed: quantity <= minQuantity ? null : _decrease,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              formattedQuantity,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 46),
            onPressed: quantity >= maxQuantity ? null : _increase,
          ),
        ],
      ),
    );
  }
}

class _SellerChatPrompt extends StatelessWidget {
  final String sellerId;
  final VoidCallback onTap;

  const _SellerChatPrompt({
    required this.sellerId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user != null && !user.isGuest && user.id == sellerId) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 15,
              color: AmazonColors.link,
            ),
            SizedBox(width: 6),
            Text(
              'Imaš pitanje? Pošalji poruku prodavcu',
              style: TextStyle(
                color: AmazonColors.link,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
