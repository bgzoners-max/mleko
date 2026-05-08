import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/profile_display_names.dart';
import '../../core/responsive.dart';
import '../../models/review_model.dart';
import '../../models/seller_stats_model.dart';
import '../../providers/app_state.dart';
import 'package:mleko/services/services.dart';
import '../../widgets/add_review_dialog.dart';
import '../../widgets/seller_review_widgets.dart';

class SellerReviewsSection extends StatefulWidget {
  final String sellerId;

  const SellerReviewsSection({super.key, required this.sellerId});

  @override
  State<SellerReviewsSection> createState() => _SellerReviewsSectionState();
}

class _SellerReviewsSectionState extends State<SellerReviewsSection> {
  int _refreshKey = 0;
  bool _expanded = true;

  void _refresh() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final canReview =
        user != null && !user.isGuest && user.id != widget.sellerId;
    final isSeller =
        user != null && !user.isGuest && user.id == widget.sellerId;
    final isWide = Breakpoints.useTwoPaneLayout(context);
    final cardPadding = Breakpoints.adaptiveDouble(
      context,
      phone: 16,
      largeTabletValue: 18,
      desktop: 18,
    );

    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(_refreshKey),
      future: Future.wait([
        context.read<ReviewsService>().getSellerStats(widget.sellerId),
        context.read<ReviewsService>().getReviewsForSeller(widget.sellerId),
        if (canReview)
          context.read<ReviewsService>().getReviewableOrder(user.id, widget.sellerId),
      ]).then((r) async {
        final reviews = r[1] as List<ReviewModel>;
        final buyerNames =
            await fetchProfileDisplayNames(reviews.map((e) => e.buyerId));
        return {
          'stats': r[0],
          'reviews': reviews,
          'reviewable': r.length > 2 ? r[2] : null,
          'buyerNames': buyerNames,
        };
      }),
      builder: (context, snap) {
        if (snap.hasError) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recenzije',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Greška pri učitavanju: ${snap.error}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting || !snap.hasData) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                children: [
                  Text(
                    'Recenzije',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
          );
        }
        final stats = snap.data!['stats'] as SellerStatsModel;
        final reviews = snap.data!['reviews'] as List<ReviewModel>;
        final reviewable = snap.data!['reviewable'] as ({
          String orderId,
          String productId,
          String productName
        })?;
        final buyerNames = snap.data!['buyerNames'] as Map<String, String>;
        return Card(
          margin: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isSeller)
                      Expanded(
                        child: InkWell(
                          onTap: () => context
                              .push('/seller/${widget.sellerId}/reviews'),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 4),
                            child: Row(
                              children: [
                                Text(
                                  'Recenzije',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                if (stats.avgRating != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.star,
                                      color: Colors.amber.shade700, size: 18),
                                  Text(stats.avgRating!.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(' (${stats.reviewCount})',
                                      style: TextStyle(
                                          color: Colors.grey.shade600)),
                                ],
                                const Spacer(),
                                Icon(Icons.chevron_right,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      )
                    else ...[
                      Text('Recenzije',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (stats.avgRating != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.star,
                            color: Colors.amber.shade700, size: 18),
                        Text(stats.avgRating!.toStringAsFixed(1),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(' (${stats.reviewCount})',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        onPressed: () {
                          setState(() {
                            _expanded = !_expanded;
                          });
                        },
                      ),
                    ],
                  ],
                ),
                if (isSeller) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Otvorite da biste videli sve recenzije i odgovorili kupcima.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                if (!isSeller && _expanded) ...[
                  if (reviewable != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.star_outline, size: 20),
                        label: const Text('Oceni prodavca'),
                        onPressed: () =>
                            _showReviewDialog(context, user, reviewable),
                      ),
                    ),
                  ],
                  if (reviews.isEmpty && reviewable == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Još nema recenzija.',
                          style: TextStyle(color: Colors.grey.shade600)),
                    )
                  else if (reviews.isNotEmpty) ...[
                    ...reviews.take(5).map((r) => Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SellerReviewListItem(
                            review: r,
                            isSeller: isSeller,
                            onRefresh: _refresh,
                            reviewerDisplayName:
                                buyerNames[r.buyerId] ?? 'Kupac',
                            onReviewerTap: () =>
                                context.push('/buyer/${r.buyerId}'),
                          ),
                        )),
                    if (reviews.length > 5) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton(
                          onPressed: () => _showAllReviews(
                              context, reviews, isSeller, buyerNames),
                          child: Text('Prikaži sve (${reviews.length})'),
                        ),
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, dynamic user,
      ({String orderId, String productId, String productName}) reviewable) {
    showDialog(
      context: context,
      builder: (ctx) => AddReviewDialog(
        buyerId: user.id,
        sellerId: widget.sellerId,
        productId: reviewable.productId,
        orderId: reviewable.orderId,
        productName: reviewable.productName,
        onSubmitted: _refresh,
      ),
    );
  }

  void _showAllReviews(
    BuildContext context,
    List<ReviewModel> reviews,
    bool isSeller,
    Map<String, String> buyerNames,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SellerAllReviewsSheet(
        reviews: reviews,
        isSeller: isSeller,
        onRefresh: _refresh,
        buyerNames: buyerNames,
      ),
    );
  }
}

class SellerAllReviewsSheet extends StatefulWidget {
  final List<ReviewModel> reviews;
  final bool isSeller;
  final VoidCallback onRefresh;
  final Map<String, String> buyerNames;

  const SellerAllReviewsSheet({
    super.key,
    required this.reviews,
    required this.isSeller,
    required this.onRefresh,
    required this.buyerNames,
  });

  @override
  State<SellerAllReviewsSheet> createState() => _SellerAllReviewsSheetState();
}

class _SellerAllReviewsSheetState extends State<SellerAllReviewsSheet> {
  void _refresh() {
    widget.onRefresh();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  'Sve recenzije (${widget.reviews.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: widget.reviews.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (_, i) {
                final r = widget.reviews[i];
                return SellerReviewListItem(
                  review: r,
                  isSeller: widget.isSeller,
                  onRefresh: _refresh,
                  reviewerDisplayName: widget.buyerNames[r.buyerId] ?? 'Kupac',
                  onReviewerTap: () {
                    Navigator.pop(context);
                    context.push('/buyer/${r.buyerId}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
