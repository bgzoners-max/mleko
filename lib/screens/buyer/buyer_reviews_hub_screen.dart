import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/buyer_review_model.dart';
import '../../models/review_model.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/buyer_review_widgets.dart';
import '../../widgets/skeleton.dart';

/// Međusobno ocenjivanje: primljene ocene od prodavaca (sa jednim odgovorom) i ostavljene prodavcima.
class BuyerReviewsHubScreen extends StatefulWidget {
  final String buyerId;

  const BuyerReviewsHubScreen({super.key, required this.buyerId});

  @override
  State<BuyerReviewsHubScreen> createState() => _BuyerReviewsHubScreenState();
}

class _BuyerReviewsHubScreenState extends State<BuyerReviewsHubScreen> {
  int _refreshKey = 0;

  void _refresh() => setState(() => _refreshKey++);

  Future<Map<String, dynamic>> _load() async {
    final reviewsService = context.read<ReviewsService>();
    final results = await Future.wait([
      reviewsService.getReviewsByBuyer(widget.buyerId),
      reviewsService.getReviewsForBuyer(widget.buyerId),
    ]);
    final reviewsLeftByBuyer = results[0] as List<ReviewModel>;
    final reviewsForBuyer = results[1] as List<BuyerReviewModel>;

    final sellerIds = <String>{
      ...reviewsLeftByBuyer.map((r) => r.sellerId),
      ...reviewsForBuyer.map((r) => r.sellerId),
    }.toList();
    final Map<String, String> sellerNames = {};
    if (sellerIds.isNotEmpty) {
      final profiles = await Supabase.instance.client
          .from('public_profiles')
          .select('id, farm_name, display_name')
          .inFilter('id', sellerIds);
      for (final p in profiles as List) {
        sellerNames[p['id'] as String] =
            (p['farm_name'] ?? p['display_name']) as String? ?? 'Prodavac';
      }
    }

    return {
      'reviewsLeftByBuyer': reviewsLeftByBuyer,
      'reviewsForBuyer': reviewsForBuyer,
      'sellerNames': sellerNames,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null ||
        user.isGuest ||
        user.isSeller ||
        user.id != widget.buyerId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recenzije')),
        body: AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Privatan pristup',
          subtitle: 'Ovu stranicu može da vidi samo kupac na svom nalogu.',
          ctaLabel: 'Nazad',
          ctaIcon: Icons.arrow_back,
          onCtaPressed: () => context.pop(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recenzije'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_refreshKey),
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const OrderListSkeleton();
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Greška: ${snap.error}'),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _refresh, child: const Text('Pokušaj ponovo')),
                  ],
                ),
              ),
            );
          }
          final data = snap.data!;
          final reviewsLeftByBuyer = data['reviewsLeftByBuyer'] as List<ReviewModel>;
          final reviewsForBuyer = data['reviewsForBuyer'] as List<BuyerReviewModel>;
          final sellerNames = data['sellerNames'] as Map<String, String>;

          if (reviewsForBuyer.isEmpty && reviewsLeftByBuyer.isEmpty) {
            return AppEmptyState(
              icon: Icons.reviews_outlined,
              title: 'Još nema recenzija',
              subtitle: 'Kada obavite prve kupovine, ovde ćete moći da ocenite prodavce i vidite njihove utiske o vama.',
              ctaLabel: 'Istraži proizvode',
              onCtaPressed: () => context.go('/'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 22, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Prodavac i kupac mogu jedan drugog da ocene posle isporuke. '
                          'Na svaku primljenu ocenu dozvoljen je samo jedan odgovor (zahvalnica ili pojašnjenje) — '
                          'bez dalje rasprave. Recenzije ne možete brisati.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Primljene ocene od prodavaca',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (reviewsForBuyer.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Još niste dobili ocenu od prodavca.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ...reviewsForBuyer.map((r) {
                  final name = sellerNames[r.sellerId] ?? 'Prodavac';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BuyerReceivedReviewListItem(
                        review: r,
                        sellerName: name,
                        isOwner: true,
                        onRefresh: _refresh,
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              Text(
                'Moje ocene prodavcima',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (reviewsLeftByBuyer.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Još niste ostavili recenziju prodavcu.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ...reviewsLeftByBuyer.map((r) {
                  final name = sellerNames[r.sellerId] ?? 'Prodavac';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _HubReviewLeftTile(
                        review: r,
                        sellerName: name,
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
        ),
      ),
    );
  }
}

class _HubReviewLeftTile extends StatelessWidget {
  final ReviewModel review;
  final String sellerName;

  const _HubReviewLeftTile({required this.review, required this.sellerName});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => context.push('/seller/${review.sellerId}'),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    Icon(Icons.storefront_outlined,
                        size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sellerName,
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
            Text(
              DateFormat('d. MMM yyyy.', 'sr').format(review.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              i < review.rating ? Icons.star : Icons.star_border,
              size: 18,
              color: Colors.amber.shade700,
            ),
          ),
        ),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
        if (review.sellerReply != null && review.sellerReply!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Odgovor prodavca',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  review.sellerReply!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
