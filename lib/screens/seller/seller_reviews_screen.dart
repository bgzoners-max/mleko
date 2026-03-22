import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/profile_display_names.dart';
import '../../models/review_model.dart';
import '../../models/seller_stats_model.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';
import '../../widgets/seller_review_widgets.dart';

/// Pregled svih recenzija za prodavca — odgovori, zahvalnice; brisanje nije dozvoljeno (RLS).
class SellerReviewsScreen extends StatefulWidget {
  final String sellerId;

  const SellerReviewsScreen({super.key, required this.sellerId});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  int _refreshKey = 0;

  void _refresh() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest || !user.isSeller || user.id != widget.sellerId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recenzije')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Ovu stranicu mogu da vide samo vlasnici prodavnice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Nazad'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recenzije'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_refreshKey),
        future: Future.wait([
          ReviewsService().getSellerStats(widget.sellerId),
          ReviewsService().getReviewsForSeller(widget.sellerId),
        ]).then((r) async {
          final reviews = r[1] as List<ReviewModel>;
          final buyerIds = reviews.map((x) => x.buyerId).toSet();
          final buyerNames = await fetchProfileDisplayNames(buyerIds);
          return {'stats': r[0], 'reviews': reviews, 'buyerNames': buyerNames};
        }),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 12),
                    Text('Greška: ${snap.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _refresh, child: const Text('Pokušaj ponovo')),
                  ],
                ),
              ),
            );
          }
          final stats = snap.data!['stats'] as SellerStatsModel;
          final reviews = snap.data!['reviews'] as List<ReviewModel>;
          final buyerNames = snap.data!['buyerNames'] as Map<String, String>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (stats.avgRating != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade700, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          stats.avgRating!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          ' (${stats.reviewCount})',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              if (stats.avgRating != null) const SizedBox(height: 16),
              if (reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Text(
                      'Još nema recenzija.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ...reviews.asMap().entries.map((e) {
                  final i = e.key;
                  final r = e.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: i < reviews.length - 1 ? 20 : 0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SellerReviewListItem(
                          review: r,
                          isSeller: true,
                          onRefresh: _refresh,
                          reviewerDisplayName: buyerNames[r.buyerId] ?? 'Kupac',
                          onReviewerTap: () => context.push('/buyer/${r.buyerId}'),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
