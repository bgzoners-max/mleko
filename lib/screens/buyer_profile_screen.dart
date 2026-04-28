import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/responsive.dart';
import '../core/utils/error_messages.dart';
import '../models/buyer_review_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import 'package:mleko/services/services.dart';

import '../widgets/app_error_retry.dart';
import '../widgets/buyer_review_widgets.dart';
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
          .from('profiles')
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
            appBar: AppBar(title: const Text('Profil kupca')),
            body: AppErrorRetry(
              message: 'Greška pri učitavanju profila.',
              detail: snap.error?.toString(),
              onRetry: _retry,
            ),
          );
        }
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil kupca')),
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
          appBar: AppBar(title: Text(displayName)),
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
                    _BuyerHeaderCard(
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
                              (r) => _BuyerReviewTile(
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
                              (r) => _ReviewTile(
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

// ─── Header sa statistikom i kontakt dugmetom ─────────────────────────────────

class _BuyerHeaderCard extends StatelessWidget {
  final UserModel? user;
  final String displayName;
  final int ordersCount;
  final String buyerId;
  final double? avgBuyerRating;
  final int buyerReviewCount;

  const _BuyerHeaderCard({
    required this.user,
    required this.displayName,
    required this.ordersCount,
    required this.buyerId,
    required this.avgBuyerRating,
    required this.buyerReviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppState>().user;
    final canContact = currentUser != null &&
        !currentUser.isGuest &&
        currentUser.id != buyerId;

    final hasStats = ordersCount > 0 || avgBuyerRating != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (hasStats) ...[
              _BuyerReputationStrip(
                ordersCount: ordersCount,
                avgBuyerRating: avgBuyerRating,
                buyerReviewCount: buyerReviewCount,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: user?.profileImageUrl != null
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null
                      ? Icon(Icons.person,
                          size: 32, color: Colors.grey.shade600)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (user?.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Član od ${DateFormat('MMM yyyy.', 'sr').format(user!.createdAt!)}',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Kontakt dugme — vidljivo prodavcima i svima koji nisu taj kupac
            if (canContact) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _ContactBuyerButton(buyerId: buyerId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BuyerReputationStrip extends StatelessWidget {
  final int ordersCount;
  final double? avgBuyerRating;
  final int buyerReviewCount;

  const _BuyerReputationStrip({
    required this.ordersCount,
    required this.avgBuyerRating,
    required this.buyerReviewCount,
  });

  String? _deliveredLabel() {
    final n = ordersCount;
    if (n <= 0) return null;
    if (n == 1) return '1 uspešno isporučena porudžbina';
    if (n >= 2 && n <= 4) return '$n uspešno isporučene porudžbine';
    return '$n uspešno isporučenih porudžbina';
  }

  @override
  Widget build(BuildContext context) {
    final delivered = _deliveredLabel();
    final rating = avgBuyerRating;

    if (delivered == null && rating == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (rating != null)
          Expanded(
            child: Row(
              children: [
                Icon(Icons.star_rounded,
                    size: 18, color: Colors.amber.shade700),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Prosečna ocena',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${rating.toStringAsFixed(1)} ($buyerReviewCount)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (delivered != null)
          Expanded(
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 18, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Uspešne porudžbine',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        delivered,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ContactBuyerButton extends StatefulWidget {
  final String buyerId;
  const _ContactBuyerButton({required this.buyerId});

  @override
  State<_ContactBuyerButton> createState() => _ContactBuyerButtonState();
}

class _ContactBuyerButtonState extends State<_ContactBuyerButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(48, 48),
      ),
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chat_outlined, size: 18),
      label: const Text('Pošalji poruku'),
      onPressed: _loading ? null : _openChat,
    );
  }

  Future<void> _openChat() async {
    final currentUser = context.read<AppState>().user;
    final chatService = context.read<ChatService>();
    if (currentUser == null) return;
    setState(() => _loading = true);
    try {
      final convId = await chatService.getOrCreateConversation(
        widget.buyerId,
        currentUser.id,
      );
      if (mounted) context.push('/chat/$convId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Review tile (ime prodavca unapred prosleđeno, bez N+1) ───────────────────

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  final String sellerName;

  const _ReviewTile({required this.review, required this.sellerName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                        Icon(
                          Icons.storefront_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sellerName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
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
          ],
        ),
      ),
    );
  }
}

class _BuyerReviewTile extends StatelessWidget {
  final BuyerReviewModel review;
  final String sellerName;

  const _BuyerReviewTile({required this.review, required this.sellerName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                        Icon(
                          Icons.storefront_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sellerName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
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
            if (!review.hasNoReply) ...[
              const SizedBox(height: 10),
              BuyerReplyPublicBlock(
                reply: review.buyerReply!,
                replyAt: review.buyerReplyAt,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
