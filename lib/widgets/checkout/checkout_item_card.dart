import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../utils/quantity_engine.dart';

class CheckoutItemCard extends StatelessWidget {
  final ({ProductModel product, double quantity}) item;
  final Animation<double> animation;
  final bool isRemoving;
  final ValueChanged<double>? onQuantityChanged;
  final VoidCallback? onRemove;

  const CheckoutItemCard({
    super.key,
    required this.item,
    required this.animation,
    this.isRemoving = false,
    this.onQuantityChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = item.product;

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
                      onPressed: isRemoving || item.quantity <= p.minOrderKg
                          ? null
                          : () => onQuantityChanged?.call(
                              QuantityEngine.normalizeQuantity(
                                quantity: item.quantity - step,
                                minQuantity: p.minOrderKg,
                                step: step,
                              )),
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
                      onPressed: isRemoving
                          ? null
                          : () => onQuantityChanged?.call(
                              QuantityEngine.normalizeQuantity(
                                quantity: item.quantity + step,
                                minQuantity: p.minOrderKg,
                                step: step,
                              )),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ukloni proizvod',
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade400),
                      onPressed: isRemoving ? null : onRemove,
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
}
