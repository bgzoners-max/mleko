import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
import '../../core/haptic.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';
import '../../services/communication/chat_service.dart';
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
      _quantity = widget.product.minOrderKg > 0 ? widget.product.minOrderKg : 1.0;
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
              'Dodato u korpu (${widget.product.formatQuantity(_quantity)}).'),
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
          content: Text(result.error?.getUserMessage() ??
              'Greška pri dodavanju u korpu.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openChat() async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      context.push('/login');
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
      if (mounted) context.push('/chat/$convId');
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
    final step = widget.product.quantityStep;
    final maxAvailable = widget.product.availableKg > 0
        ? widget.product.availableKg
        : 99999.0;
    final totalPrice = _quantity * widget.product.pricePerKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.product.isAvailable) ...[
          Row(
            children: [
              // Stepper za biranje količine
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? AmazonColors.darkCard : const Color(0xFFF7F8F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AmazonColors.darkBorder
                        : AmazonColors.borderGray,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 46),
                      onPressed: _quantity <= widget.product.minOrderKg
                          ? null
                          : () {
                              setState(() {
                                final next = _quantity - step;
                                _quantity = next < widget.product.minOrderKg
                                    ? widget.product.minOrderKg
                                    : QuantityEngine.normalizeQuantity(
                                        quantity: next,
                                        minQuantity: widget.product.minOrderKg,
                                        step: step,
                                      );
                              });
                            },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        widget.product.formatQuantity(_quantity),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 46),
                      onPressed: _quantity >= maxAvailable
                          ? null
                          : () {
                              setState(() {
                                final next = _quantity + step;
                                _quantity = next > maxAvailable
                                    ? maxAvailable
                                    : QuantityEngine.normalizeQuantity(
                                        quantity: next,
                                        minQuantity: widget.product.minOrderKg,
                                        step: step,
                                      );
                              });
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Dugme "Dodaj u korpu"
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: BounceTapButton(
                    onPressed: () => withHaptic(() => _addToCart(), medium: true),
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
          ),
        ] else ...[
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
        ],
        const SizedBox(height: 8),
        // Sekundarni link za poruku prodavcu
        Builder(builder: (context) {
          final user = context.watch<AppState>().user;
          if (user != null && !user.isGuest && user.id == widget.product.sellerId) {
            return const SizedBox.shrink();
          }
          return InkWell(
            onTap: _openChat,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 15, color: AmazonColors.link),
                  const SizedBox(width: 6),
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
        }),
        const SizedBox(height: 8),
        SellerInlineCartSection(sellerId: widget.product.sellerId),
      ],
    );
  }
}
