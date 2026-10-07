import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../services/social/social_services.dart';

/// Dugme „Oceni kupca" — prikazuje se samo ako prodavac sme da oceni.
class CanSellerReviewBuyerButton extends StatefulWidget {
  final String sellerId;
  final OrderModel order;
  final VoidCallback onPressed;

  const CanSellerReviewBuyerButton({
    super.key,
    required this.sellerId,
    required this.order,
    required this.onPressed,
  });

  @override
  State<CanSellerReviewBuyerButton> createState() =>
      _CanSellerReviewBuyerButtonState();
}

class _CanSellerReviewBuyerButtonState
    extends State<CanSellerReviewBuyerButton> {
  Future<bool>? _canReviewFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _canReviewFuture ??= context
        .read<ReviewsService>()
        .canSellerReviewBuyer(widget.sellerId, widget.order.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canReviewFuture,
      builder: (ctx, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return FilledButton.tonalIcon(
          icon: const Icon(Icons.star_outline, size: 18),
          label: const Text('Oceni kupca'),
          onPressed: widget.onPressed,
        );
      },
    );
  }
}
