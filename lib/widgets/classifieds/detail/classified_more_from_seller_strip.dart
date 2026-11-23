import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system.dart' show AmazonColors;
import '../../../models/classified_ad_model.dart';
import '../../../theme/app_design.dart';
import '../../app_network_image.dart';

/// Prikazuje ostale aktivne oglase istog oglašivača ispod opisa oglasa
/// i pruža modalni dijalog za pregled svih oglasa prodavca ("Svi oglasi").
class ClassifiedMoreFromSellerStrip extends StatelessWidget {
  const ClassifiedMoreFromSellerStrip({
    super.key,
    required this.sellerName,
    required this.otherAds,
    required this.isDark,
    required this.onViewAll,
  });

  final String sellerName;
  final List<ClassifiedAdModel> otherAds;
  final bool isDark;
  final VoidCallback onViewAll;

  static Future<void> showAllSellerAdsModal(
    BuildContext context, {
    required String sellerName,
    required List<ClassifiedAdModel> ads,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Svi oglasi — $sellerName (${ads.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ads.isEmpty
                      ? const Center(
                          child: Text('Oglašivač trenutno nema drugih oglasa.'),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(14),
                          itemCount: ads.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final item = ads[index];
                            return _SellerAdListTile(
                              ad: item,
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(ctx).pop();
                                context.push('/classifieds/ad/${item.id}');
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (otherAds.isEmpty) return const SizedBox.shrink();

    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
    final borderColor =
        isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;
    final linkColor = isDark ? AmazonColors.lightGreen : AmazonColors.link;
    final previewAds = otherAds.take(4).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceM),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Još oglasa od $sellerName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'Svi (${otherAds.length})',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: linkColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: previewAds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final item = previewAds[idx];
                return SizedBox(
                  width: 155,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.push('/classifieds/ad/${item.id}'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AmazonColors.darkCanvas
                            : const Color(0xFFF7F8F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(9),
                            ),
                            child: SizedBox(
                              height: 98,
                              child: item.images.isNotEmpty
                                  ? AppNetworkImage.thumbnail(
                                      imageUrl: item.images.first,
                                      fit: BoxFit.cover,
                                    )
                                  : const Center(
                                      child: Icon(Icons.image_outlined),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.priceFormatted,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? const Color(0xFFFF6B6B)
                                        : AmazonColors.dealRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerAdListTile extends StatelessWidget {
  const _SellerAdListTile({
    required this.ad,
    required this.isDark,
    required this.onTap,
  });

  final ClassifiedAdModel ad;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 60,
                child: ad.images.isNotEmpty
                    ? AppNetworkImage.thumbnail(
                        imageUrl: ad.images.first,
                        fit: BoxFit.cover,
                      )
                    : const Center(child: Icon(Icons.image_outlined)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        ad.priceFormatted,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFFF6B6B)
                              : AmazonColors.dealRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· ${ad.city}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AmazonColors.darkTextSecondary
                              : AmazonColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
