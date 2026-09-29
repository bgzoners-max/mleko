import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_reviews_data.dart';
import '../../models/review_model.dart';

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
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final reviewsData = snapshot.data!;
        final averageRating = reviewsData.averageRating;
        final reviews = reviewsData.reviews;
        final buyerDisplayNames = reviewsData.buyerDisplayNames;

        if (averageRating == null && reviews.isEmpty) {
          return const SizedBox.shrink();
        }

        final visibleReviews = _showAll
            ? reviews
            : reviews.take(3).toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recenzije',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (averageRating != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 2),
                  Text(averageRating.toStringAsFixed(1)),
                  Text(
                    ' (${reviews.length})',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (reviews.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final review in visibleReviews)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProductReviewTile(
                    review: review,
                    reviewerName:
                        buyerDisplayNames[review.buyerId] ?? 'Kupac',
                  ),
                ),
              if (reviews.length > 3)
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll
                        ? 'Prikaži manje'
                        : 'Prikaži sve (${reviews.length})',
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _ProductReviewTile extends StatelessWidget {
  final ReviewModel review;
  final String reviewerName;

  const _ProductReviewTile({
    required this.review,
    required this.reviewerName,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => context.push('/buyer/${review.buyerId}'),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reviewerName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: scheme.primary),
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
                (index) => Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  size: 14,
                  color: Colors.amber.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                review.comment.isEmpty ? '(bez komentara)' : review.comment,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
