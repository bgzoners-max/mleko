import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../models/seller_stats_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/chat_service.dart';
import '../../services/favorite_sellers_service.dart';
import '../../services/products_service.dart';
import '../../services/reviews_service.dart';
import '../../services/users_service.dart';
import '../../core/responsive.dart';
import '../../widgets/add_review_dialog.dart';
import '../../widgets/product_grid_tile.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;

  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  late final Future<UserModel?> _userFuture =
      UsersService().getUser(widget.sellerId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Proizvođač')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final seller = userSnap.data;
        if (seller == null || !seller.isSeller) {
          return Scaffold(
            appBar: AppBar(title: const Text('Proizvođač')),
            body: const Center(child: Text('Prodavac nije pronađen.')),
          );
        }
        return _SellerProfileContent(seller: seller);
      },
    );
  }
}

class _SellerProfileContent extends StatelessWidget {
  final UserModel seller;

  const _SellerProfileContent({required this.seller});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final draftCount = cart.getSellerDraft(seller.id).length;
    final sellerName = seller.farmName ?? 'Proizvođač';
    return Scaffold(
      appBar: AppBar(
        title: Text(sellerName),
        actions: [
          if (draftCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: TextButton(
                  onPressed: () => context.push('/checkout-seller/${seller.id}'),
                  child: Text('Porudžbina ($draftCount)'),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _SellerOrderDraftBar(sellerId: seller.id),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(seller: seller),
            _ChatButton(sellerId: seller.id),
            if (seller.sellerTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              _SellerTagsRow(tags: seller.sellerTags),
            ],
            if (seller.sellerStory != null && seller.sellerStory!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _SellerStorySection(story: seller.sellerStory!),
            ],
            if (seller.farmGalleryUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              _FarmGallerySection(urls: seller.farmGalleryUrls),
            ],
            const SizedBox(height: 16),
            _ReviewsSection(sellerId: seller.id),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Mini prodavnica',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            _ProductGrid(sellerId: seller.id),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  final UserModel seller;

  const _ProfileHeader({required this.seller});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  final _favSellersService = FavoriteSellersService();
  bool _isFollowing = false;
  bool _loading = false;
  bool _checked = false;
  late final Future<int> _followersFuture =
      FavoriteSellersService().getFollowersCount(widget.seller.id);

  @override
  void initState() {
    super.initState();
    _checkFollowing();
  }

  Future<void> _checkFollowing() async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) return;
    final following = await _favSellersService.isFollowing(user.id, widget.seller.id);
    if (mounted) setState(() { _isFollowing = following; _checked = true; });
  }

  Future<void> _toggleFollow() async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      context.go('/login');
      return;
    }
    setState(() => _loading = true);
    await _favSellersService.toggleFollow(user.id, widget.seller.id);
    if (mounted) setState(() { _isFollowing = !_isFollowing; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final seller = widget.seller;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: seller.profileImageUrl != null
                  ? CachedNetworkImageProvider(seller.profileImageUrl!)
                  : null,
              child: seller.profileImageUrl == null
                  ? Icon(Icons.store, size: 40, color: Colors.grey.shade600)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          seller.farmName ?? 'Gazdinstvo',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (seller.isVerified) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Proveren prodavac',
                          child: Icon(Icons.verified, color: Theme.of(context).colorScheme.primary, size: 20),
                        ),
                      ],
                    ],
                  ),
                  if (seller.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Član od ${DateFormat('dd.MM.yyyy', 'sr').format(seller.createdAt!)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                  if (seller.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(seller.location!, style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ],
                  // Broj pratilaca — vidljiv kupcima
                  FutureBuilder<int>(
                    future: _followersFuture,
                    builder: (_, snap) {
                      final count = snap.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.people_outline, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '$count pratilac${count == 1 ? '' : 'a'}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_checked) ...[
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _loading ? null : _toggleFollow,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isFollowing ? 'Ne prati' : 'Prati'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  final String sellerId;

  const _ChatButton({required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest || user.id == sellerId) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            final convId = await ChatService().getOrCreateConversation(user.id, sellerId);
            if (context.mounted) context.push('/chat/$convId');
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
        icon: const Icon(Icons.chat),
        label: const Text('Pošalji poruku'),
      ),
    );
  }
}

class _SellerStorySection extends StatelessWidget {
  final String story;

  const _SellerStorySection({required this.story});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O gazdinstvu', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(story, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _FarmGallerySection extends StatelessWidget {
  final List<String> urls;

  const _FarmGallerySection({required this.urls});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Galerija', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: urls.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: urls[i],
                  width: 120,
                  memCacheWidth: 240,
                  memCacheHeight: 240,
                  height: 120,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => ColoredBox(color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewsSection extends StatefulWidget {
  final String sellerId;

  const _ReviewsSection({required this.sellerId});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  int _refreshKey = 0;

  void _refresh() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final canReview = user != null && !user.isGuest && user.id != widget.sellerId;
    final isSeller = user != null && !user.isGuest && user.id == widget.sellerId;

    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(_refreshKey),
      future: Future.wait([
        ReviewsService().getSellerStats(widget.sellerId),
        ReviewsService().getReviewsForSeller(widget.sellerId),
        if (canReview) ReviewsService().getReviewableOrder(user.id, widget.sellerId),
      ]).then((r) => {
        'stats': r[0],
        'reviews': r[1],
        'reviewable': r.length > 2 ? r[2] : null,
      }),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final stats = snap.data!['stats'] as SellerStatsModel;
        final reviews = snap.data!['reviews'] as List<ReviewModel>;
        final reviewable = snap.data!['reviewable'] as ({String orderId, String productId, String productName})?;
        if (!stats.hasAnyData && reviews.isEmpty && reviewable == null) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stats.hasAnyData) ...[
                  _SellerTrustRow(stats: stats),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Text('Recenzije', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (stats.avgRating != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                      Text(stats.avgRating!.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(' (${stats.reviewCount})', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ],
                ),
                if (reviewable != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.star_outline, size: 20),
                      label: const Text('Oceni prodavca'),
                      onPressed: () => _showReviewDialog(context, user, reviewable),
                    ),
                  ),
                ],
                if (reviews.isEmpty && reviewable == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Nema recenzija.', style: TextStyle(color: Colors.grey.shade600)),
                  )
                else if (reviews.isNotEmpty) ...[
                  ...reviews.take(5).map((r) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ReviewItem(
                      review: r,
                      isSeller: isSeller,
                      onRefresh: _refresh,
                    ),
                  )),
                  if (reviews.length > 5) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton(
                        onPressed: () => _showAllReviews(context, reviews, isSeller),
                        child: Text('Prikaži sve (${reviews.length})'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, dynamic user, ({String orderId, String productId, String productName}) reviewable) {
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
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AllReviewsSheet(
        reviews: reviews,
        isSeller: isSeller,
        onRefresh: _refresh,
      ),
    );
  }
}

// ─── Bottom sheet: sve recenzije ──────────────────────────────────────────────

class _AllReviewsSheet extends StatefulWidget {
  final List<ReviewModel> reviews;
  final bool isSeller;
  final VoidCallback onRefresh;

  const _AllReviewsSheet({
    required this.reviews,
    required this.isSeller,
    required this.onRefresh,
  });

  @override
  State<_AllReviewsSheet> createState() => _AllReviewsSheetState();
}

class _AllReviewsSheetState extends State<_AllReviewsSheet> {
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
              itemBuilder: (_, i) => _ReviewItem(
                review: widget.reviews[i],
                isSeller: widget.isSeller,
                onRefresh: _refresh,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tagovi prodavca ──────────────────────────────────────────────────────────

class _SellerTagsRow extends StatelessWidget {
  final List<String> tags;
  const _SellerTagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    final normalized = tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    const trustLabels = [
      'Provereno gazdinstvo',
      'Redovna isporuka',
      'Dostava u vaš grad',
    ];
    final trustTags = <String>[];
    final otherTags = <String>[];

    for (final t in normalized) {
      if (trustLabels.any((lbl) => lbl.toLowerCase() == t.toLowerCase())) {
        trustTags.add(t);
      } else {
        otherTags.add(t);
      }
    }

    if (normalized.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];

    if (trustTags.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: trustTags.map((t) {
              IconData icon;
              Color color;
              String tooltip;
              final lower = t.toLowerCase();
              if (lower == 'provereno gazdinstvo') {
                icon = Icons.verified;
                color = Colors.green.shade700;
                tooltip = 'Gazdinstvo je provereno od strane platforme.';
              } else if (lower == 'redovna isporuka') {
                icon = Icons.autorenew;
                color = Colors.blue.shade700;
                tooltip = 'Prodavac redovno isporučuje porudžbine na vreme.';
              } else {
                icon = Icons.local_shipping_outlined;
                color = Colors.orange.shade800;
                tooltip = 'Prodavac organizuje dostavu u vaš grad (ili dogovorom).';
              }
              return Tooltip(
                message: tooltip,
                child: Chip(
                  avatar: Icon(icon, size: 16, color: Colors.white),
                  label: Text(
                    t,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  backgroundColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    if (otherTags.isNotEmpty) {
      children.add(
        Padding(
          padding: EdgeInsets.fromLTRB(16, trustTags.isNotEmpty ? 8 : 0, 16, 0),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: otherTags
                .map((t) => Chip(
                      avatar: const Icon(Icons.label_outline, size: 14),
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

// ─── Review item ──────────────────────────────────────────────────────────────

class _ReviewItem extends StatelessWidget {
  final ReviewModel review;
  final bool isSeller;
  final VoidCallback onRefresh;

  const _ReviewItem({
    required this.review,
    required this.isSeller,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final canAct = isSeller && review.isReplyEditable;
    final hasReply = !review.hasNoReply;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Recenzija kupca ──────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                  if (review.comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      review.comment,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
            if (canAct) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: Icon(
                  hasReply ? Icons.edit_outlined : Icons.reply_outlined,
                  size: 16,
                ),
                label: Text(
                  hasReply ? 'Izmeni' : 'Odgovori',
                  style: const TextStyle(fontSize: 13),
                ),
                onPressed: () => _showReplyDialog(context),
              ),
            ],
          ],
        ),

        // ── Odgovor prodavca ─────────────────────────────────────
        if (hasReply) ...[
          const SizedBox(height: 8),
          _SellerReplyBlock(
            reply: review.sellerReply!,
            replyAt: review.sellerReplyAt,
          ),
        ],
      ],
    );
  }

  void _showReplyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _SellerReplyDialog(
        review: review,
        onSaved: onRefresh,
      ),
    );
  }
}

// ─── Blok odgovora prodavca ───────────────────────────────────────────────────

class _SellerReplyBlock extends StatelessWidget {
  final String reply;
  final DateTime? replyAt;

  const _SellerReplyBlock({required this.reply, this.replyAt});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: scheme.primary.withValues(alpha: 0.4), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store_outlined, size: 14, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                'Odgovor prodavca',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              if (replyAt != null) ...[
                const SizedBox(width: 6),
                Text(
                  DateFormat('d. MMM yyyy.', 'sr').format(replyAt!),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(reply, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

// ─── Dialog za pisanje / izmenu odgovora ──────────────────────────────────────

class _SellerReplyDialog extends StatefulWidget {
  final ReviewModel review;
  final VoidCallback onSaved;

  const _SellerReplyDialog({required this.review, required this.onSaved});

  @override
  State<_SellerReplyDialog> createState() => _SellerReplyDialogState();
}

class _SellerReplyDialogState extends State<_SellerReplyDialog> {
  late final TextEditingController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.review.sellerReply ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ReviewsService().addSellerReply(
        reviewId: widget.review.id,
        reply: text,
      );
      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Odgovor sačuvan.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('reply_not_editable_after_24h')
          ? 'Odgovor nije moguće menjati nakon 24h.'
          : 'Greška: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = !widget.review.hasNoReply;
    return AlertDialog(
      title: Text(hasExisting ? 'Izmeni odgovor' : 'Odgovori na recenziju'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prikaz originalne recenzije radi konteksta
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < widget.review.rating ? Icons.star : Icons.star_border,
                      size: 14,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
                if (widget.review.comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.review.comment,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            maxLength: 500,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Vaš odgovor',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          if (hasExisting)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Izmena je moguća samo unutar 24h od prvog odgovora.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}

class _SellerTrustRow extends StatelessWidget {
  final SellerStatsModel stats;

  const _SellerTrustRow({required this.stats});

  String? _deliveredLabel() {
    final n = stats.ordersCount;
    if (n <= 0) return null;
    if (n == 1) return '1 uspešno isporučena porudžbina';
    if (n >= 2 && n <= 4) return '$n uspešno isporučene porudžbine';
    return '$n uspešno isporučenih porudžbina';
  }

  @override
  Widget build(BuildContext context) {
    final chips = <_TrustChip>[];

    if (stats.avgRating != null) {
      chips.add(_TrustChip(
        icon: Icons.star_rounded,
        iconColor: Colors.amber.shade700,
        label: stats.avgRating!.toStringAsFixed(1),
      ));
    }

    if (stats.responseLabel != null) {
      chips.add(_TrustChip(
        icon: Icons.schedule,
        label: stats.responseLabel!,
      ));
    }

    final delivered = _deliveredLabel();
    if (delivered == null && chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (delivered != null) ...[
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 16, color: Colors.green.shade700),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  delivered,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          if (chips.isNotEmpty) const SizedBox(height: 8),
        ],
        if (chips.isNotEmpty)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: chips,
          ),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;

  const _TrustChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final String sellerId;

  const _ProductGrid({required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: ProductsService().getProductsBySeller(sellerId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Nema proizvoda.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = Breakpoints.productGridColumns(context);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final p = list[i];
                  final user = ctx.watch<AppState>().user;
                  final favorites = ctx.watch<FavoritesProvider>();
                  final canFavorite = user != null && !user.isGuest;
                  final canAddToOrder = user != null && !user.isGuest && user.id != sellerId && p.isAvailable;
                  return ProductGridTile(
                    product: p,
                    isFavorite: canFavorite ? favorites.isFavorite(p.id) : null,
                    onFavoriteToggle: canFavorite ? () => favorites.toggle(user.id, p.id) : null,
                    onAddToOrder: canAddToOrder
                        ? () {
                            showModalBottomSheet<void>(
                              context: ctx,
                              builder: (sheetContext) => _AddToOrderSheet(
                                product: p,
                                sellerId: sellerId,
                                cart: ctx.read<CartProvider>(),
                                onAdded: () {
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: const Text('Proizvod je dodat u porudžbinu.'),
                                      action: SnackBarAction(
                                        label: 'Pregled',
                                        onPressed: () => ctx.push('/checkout-seller/$sellerId'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        : null,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _AddToOrderSheet extends StatefulWidget {
  final ProductModel product;
  final String sellerId;
  final CartProvider cart;
  final VoidCallback onAdded;

  const _AddToOrderSheet({
    required this.product,
    required this.sellerId,
    required this.cart,
    required this.onAdded,
  });

  @override
  State<_AddToOrderSheet> createState() => _AddToOrderSheetState();
}

class _AddToOrderSheetState extends State<_AddToOrderSheet> {
  late double _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.minOrderKg;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final step = p.quantityStep;
    final max = p.availableKg;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            p.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(p.priceFormatted, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: _quantity <= p.minOrderKg
                    ? null
                    : () => setState(() {
                          final next = _quantity - step;
                          _quantity = next < p.minOrderKg ? p.minOrderKg : next.clamp(p.minOrderKg, max);
                        }),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 16),
              Text(
                p.formatQuantity(_quantity),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                onPressed: _quantity >= max
                    ? null
                    : () => setState(() => _quantity = (_quantity + step).clamp(p.minOrderKg, max)),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              widget.cart.addForSeller(
                sellerId: widget.sellerId,
                productId: p.id,
                quantity: _quantity,
              );
              Navigator.of(context).pop();
              widget.onAdded();
            },
            child: const Text('Dodaj u porudžbinu'),
          ),
        ],
      ),
    );
  }
}

class _SellerOrderDraftBar extends StatelessWidget {
  final String sellerId;

  const _SellerOrderDraftBar({required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest || user.id == sellerId) return const SizedBox.shrink();

    final cart = context.watch<CartProvider>();
    final draft = cart.getSellerDraft(sellerId);
    if (draft.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${draft.length} proizvoda u porudžbini kod ovog prodavca',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            FutureBuilder<List<({ProductModel product, double quantity})>>(
              future: cart.getProductsBySeller(sellerId),
              builder: (_, snap) {
                final items = snap.data ?? [];
                if (items.isEmpty) return const SizedBox.shrink();
                final preview = items.take(3).map((e) => e.product.name).join(', ');
                final suffix = items.length > 3 ? ' +${items.length - 3}' : '';
                return Text(
                  '$preview$suffix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                );
              },
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => context.push('/checkout-seller/$sellerId'),
              icon: const Icon(Icons.send),
              label: const Text('Nastavi porudžbinu'),
            ),
          ],
        ),
      ),
    );
  }
}
