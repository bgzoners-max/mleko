import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/responsive.dart';
import '../models/buyer_review_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import 'package:mleko/services/services.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/app_back_button.dart';
import '../widgets/profile/buyer_profile_header.dart';
import '../widgets/profile/buyer_profile_reviews_section.dart';
import '../widgets/skeleton.dart';

/// Profil kupca — vidi prodavac kada klikne na kupca u poruci ili porudžbini.
class BuyerProfileScreen extends StatefulWidget {
  final String buyerId;

  const BuyerProfileScreen({super.key, required this.buyerId});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  Future<Map<String, dynamic>>? _loadFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFuture ??= _load(widget.buyerId);
  }

  void _retry() => setState(() => _loadFuture = _load(widget.buyerId));

  Future<Map<String, dynamic>> _load(String buyerId) async {
    final usersService = context.read<UsersService>();
    final reviewsService = context.read<ReviewsService>();
    final results = await Future.wait([
      usersService.getUser(buyerId),
      reviewsService.getReviewsByBuyer(buyerId),
      reviewsService.getReviewsForBuyer(buyerId),
      _loadDeliveredOrdersCount(buyerId),
    ]);
    final reviewsLeftByBuyer = results[1] as List<ReviewModel>;
    final reviewsForBuyer = results[2] as List<BuyerReviewModel>;
    final avgBuyerRating = reviewsForBuyer.isEmpty
        ? null
        : reviewsForBuyer.fold<double>(0, (sum, r) => sum + r.rating) /
            reviewsForBuyer.length;

    // Batch-load seller names — jedan upit umesto N FutureBuilder poziva
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
      'user': results[0],
      'reviewsLeftByBuyer': reviewsLeftByBuyer,
      'reviewsForBuyer': reviewsForBuyer,
      'avgBuyerRating': avgBuyerRating,
      'sellerNames': sellerNames,
      'ordersCount': results[3] as int,
    };
  }

  static Future<int> _loadDeliveredOrdersCount(String buyerId) async {
    final list = await Supabase.instance.client
        .from('orders')
        .select('id')
        .eq('buyer_id', buyerId)
        .eq('status', 'delivered');
    return (list as List).length;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadFuture,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallbackRoute: '/'),
              title: const Text('Profil kupca'),
              actions: const [AppHomeButton()],
            ),
            body: AppErrorRetry(
              message: 'Greška pri učitavanju profila.',
              detail: snap.error?.toString(),
              onRetry: _retry,
            ),
          );
        }
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallbackRoute: '/'),
              title: const Text('Profil kupca'),
              actions: const [AppHomeButton()],
            ),
            body: const BuyerProfileSkeleton(),
          );
        }
        final user = snap.data!['user'] as UserModel?;
        final reviewsLeftByBuyer =
            snap.data!['reviewsLeftByBuyer'] as List<ReviewModel>;
        final reviewsForBuyer =
            snap.data!['reviewsForBuyer'] as List<BuyerReviewModel>;
        final avgBuyerRating = snap.data!['avgBuyerRating'] as double?;
        final sellerNames = snap.data!['sellerNames'] as Map<String, String>;
        final ordersCount = snap.data!['ordersCount'] as int;
        final displayName = user?.displayName ?? user?.farmName ?? 'Kupac';

        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(fallbackRoute: '/'),
            title: Text(displayName),
            actions: const [AppHomeButton()],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Breakpoints.formContentWidth(context),
              ),
              child: RefreshIndicator(
                onRefresh: () async => _retry(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    BuyerProfileHeader(
                      user: user,
                      displayName: displayName,
                      ordersCount: ordersCount,
                      buyerId: widget.buyerId,
                      avgBuyerRating: avgBuyerRating,
                      buyerReviewCount: reviewsForBuyer.length,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(
                          'Recenzije koje je kupac dobio',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Ocene koje su prodavci ostavili kupcu',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        children: [
                          if (reviewsForBuyer.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Text(
                                  'Kupac još nema primljene recenzije.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            )
                          else
                            ...reviewsForBuyer.map(
                              (r) => BuyerReviewTile(
                                review: r,
                                sellerName:
                                    sellerNames[r.sellerId] ?? 'Prodavac',
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        title: Text(
                          'Recenzije koje je kupac ostavio',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Ocene koje je kupac dao prodavcima',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        children: [
                          if (reviewsLeftByBuyer.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Text(
                                  'Kupac još nije ostavio recenzije.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            )
                          else
                            ...reviewsLeftByBuyer.map(
                              (r) => BuyerSentReviewTile(
                                review: r,
                                sellerName:
                                    sellerNames[r.sellerId] ?? 'Prodavac',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
