import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_network_image.dart';

class ChatItemContextCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final double? price;
  final String? unit;
  final String? productId;
  final String? adId;
  final String? itemType;

  const ChatItemContextCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.price,
    this.unit,
    this.productId,
    this.adId,
    this.itemType,
  });

  void _onTap(BuildContext context) {
    if (productId != null) {
      context.push('/product/$productId');
    } else if (adId != null) {
      context.push('/classifieds/$adId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute = productId != null || adId != null;
    final isAd = itemType == 'ad' || adId != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasRoute ? () => _onTap(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? AppNetworkImage.thumbnail(
                          imageUrl: imageUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            isAd
                                ? Icons.campaign_outlined
                                : Icons.shopping_bag_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (price != null) ...[
                            Text(
                              '${price!.toStringAsFixed(price! % 1 == 0 ? 0 : 2)} RSD${unit != null && unit!.isNotEmpty ? '/$unit' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            isAd ? 'Mali oglas' : 'Proizvod',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasRoute)
                  Icon(Icons.chevron_right, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
