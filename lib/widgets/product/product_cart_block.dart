import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
import '../../core/haptic.dart';
import '../../core/responsive.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';
import '../../services/services.dart';
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
        quantity: widget.product.minOrderKg,
      ),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final isWideLayout = MediaQuery.of(context).size.width >= 800;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Proizvod je dodat u korpu.'),
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

  @override
  Widget build(BuildContext context) {
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final button = SizedBox(
      width: widget.desktopMode ? (isLargeTablet ? 220.0 : 200.0) : double.infinity,
      height: isLargeTablet ? 50 : 52,
      child: BounceTapButton(
        onPressed: widget.product.isAvailable
            ? () => withHaptic(() => _addToCart(), medium: true)
            : null,
        builder: (onPressed) => ElevatedButton(
          onPressed: widget.product.isAvailable ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.product.isAvailable
                ? AmazonColors.amberLight
                : Colors.grey.shade300,
            foregroundColor: widget.product.isAvailable
                ? AmazonColors.darkNavy
                : Colors.grey.shade600,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: widget.product.isAvailable
                    ? AmazonColors.amberDark
                    : Colors.grey.shade400,
                width: 0.9,
              ),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              letterSpacing: 0.2,
            ),
          ),
          child: Text(widget.product.isAvailable
              ? 'Dodaj u korpu'
              : 'Trenutno nedostupno'),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, widget.desktopMode ? 16 : 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.desktopMode
              ? Align(alignment: Alignment.centerRight, child: button)
              : button,
          const SizedBox(height: 16),
          SellerInlineCartSection(sellerId: widget.product.sellerId),
        ],
      ),
    );
  }
}
