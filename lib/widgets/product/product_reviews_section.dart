import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_reviews_data.dart';

class ProductReviewsSection extends StatefulWidget {
  final Future<ProductReviewsData> reviewsFuture;

  const ProductReviewsSection({super.key, required this.reviewsFuture});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductReviewsData>(
      future: widget.reviewsFuture,
      builder: (context, snap) {
        if (snap.hasError || !snap.hasData) return const SizedBox.shrink();
        final data = snap.data!;
        final avg = data.averageRating;
        final reviews = data.reviews;
        final buyerNames = data.buyerDisplayNames;
        final scheme = Theme.of(context).colorScheme;
        if (avg == null && reviews.isEmpty) return const SizedBox.shrink();
        final visible = _showAll ? reviews : reviews.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Recenzije',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (avg != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                  Text(avg.toStringAsFixed(1)),
                  Text(' (${reviews.length})',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
            if (reviews.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...visible.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => context.push('/buyer/${r.buyerId}'),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(Icons.person_outline,
                                    size: 16, color: scheme.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    buyerNames[r.buyerId] ?? 'Kupac',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: scheme.primary,
                                        ),
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    size: 18, color: scheme.primary),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(
                                  5,
                                  (i) => Icon(
                                      i < r.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 14,
                                      color: Colors.amber.shade700)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    r.comment.isEmpty
                                        ? '(bez komentara)'
                                        : r.comment,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: scheme.onSurface))),
                          ],
                        ),
                      ],
                    ),
                  )),
              if (reviews.length > 3)
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(_showAll
                      ? 'Prikaži manje'
                      : 'Prikaži sve (${reviews.length})'),
                ),
            ],
          ],
        );
      },
    );
  }
}
