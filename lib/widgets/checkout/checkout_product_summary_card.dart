import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../app_network_image.dart';
import '../offline_indicator.dart';
import '../purchase_guidance_card.dart';

class CheckoutProductSummaryCard extends StatelessWidget {
  final ProductModel product;
  final bool isOffline;

  const CheckoutProductSummaryCard({
    super.key,
    required this.product,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PurchaseGuidanceCard(
          icon: Icons.info_outline,
          title: 'Šta će se desiti sledeće?',
          body:
              'Nakon što pošalješ upit, prodavac će ga dobiti u obaveštenjima i moći će da odluči da li prihvata porudžbinu.',
          accentColor: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              if (product.imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppNetworkImage.thumbnail(
                    imageUrl: product.imageUrls.first,
                    width: 64,
                    height: 64,
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
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
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.priceFormatted,
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
          OfflineReadOnlyBadge(isOffline: isOffline),
        ],
      ],
    );
  }
}
