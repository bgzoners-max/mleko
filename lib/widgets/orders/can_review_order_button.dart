import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import 'package:mleko/services/services.dart';

class CanReviewOrderButton extends StatefulWidget {
  final String userId;
  final OrderModel order;
  final VoidCallback onPressed;

  const CanReviewOrderButton({
    super.key,
    required this.userId,
    required this.order,
    required this.onPressed,
  });

  @override
  State<CanReviewOrderButton> createState() => _CanReviewOrderButtonState();
}

class _CanReviewOrderButtonState extends State<CanReviewOrderButton> {
  Future<bool>? _canReviewFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _canReviewFuture ??= context.read<ReviewsService>().canReviewOrder(widget.userId, widget.order.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canReviewFuture,
      builder: (ctx, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return FilledButton.tonalIcon(
          icon: const Icon(Icons.star_outline, size: 20),
          label: const Text('Ostavi recenziju'),
          onPressed: widget.onPressed,
        );
      },
    );
  }
}
