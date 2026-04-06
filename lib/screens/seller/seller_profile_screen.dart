import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../models/seller_stats_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import 'package:mleko/services/services.dart';

import '../../core/haptic.dart';
import '../../core/profile_display_names.dart';
import '../../core/responsive.dart';
import '../../widgets/add_review_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/product_grid_tile.dart';
import '../../widgets/seller_review_widgets.dart';
import '../../widgets/app_network_image.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;

  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  Future<UserModel?> _loadUser() => UsersService().getUser(widget.sellerId);
  late Future<UserModel?> _userFuture = _loadUser();

  void _retry() => setState(() => _userFuture = _loadUser());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, userSnap) {
        if (userSnap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Proizvođač')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Greška pri učitavanju profila.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userSnap.error.toString(),
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Pokušaj ponovo'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!userSnap.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Proizvođač')),
            body: const BuyerProfileSkeleton(),
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
    final draftCount = context.select<CartProvider, int>(
      (cart) => cart.getSellerDraft(seller.id).length,
    );
    final sellerName = seller.farmName ?? 'Proizvođač';
    final isDesktop = Breakpoints.isDesktop(context);
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final isWide = isDesktop || isLargeTablet;
    return Scaffold(
      appBar: AppBar(
        title: Text(sellerName),
        actions: [
          if (draftCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: TextButton(
                  onPressed: () =>
                      context.push('/checkout-seller/${seller.id}'),
                  child: Text('Porudžbina ($draftCount)'),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          _SellerOrderDraftBar(sellerId: seller.id, seller: seller),
      body: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = constraints.maxHeight;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop
                        ? 1120.0
                        : (isLargeTablet
                            ? 980.0
                            : Breakpoints.maxContentWidth(context)),
                    minHeight: minHeight > 0 ? minHeight : 400,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HEADER / PROFIL
                      _ProfileHeader(seller: seller),
                      if (seller.sellerTags.isNotEmpty) ...[
                        SizedBox(height: isSmallTablet ? 10 : 8),
                        _SellerTagsRow(tags: seller.sellerTags),
                      ],

                      // STATS (ugled / poverenje)
                      SizedBox(height: isSmallTablet ? 10 : 8),
                      _SellerSafetyStrip(seller: seller),

                      if (isWide) ...[
                        SizedBox(height: isLargeTablet ? 14 : 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Lijevo: galerija + priča + mini prodavnica
                            Expanded(
                              flex: isLargeTablet ? 5 : 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (seller.farmGalleryUrls.isNotEmpty) ...[
                                    _FarmGallerySection(
                                        urls: seller.farmGalleryUrls),
                                    SizedBox(height: isLargeTablet ? 12 : 16),
                                  ],
                                  if (seller.sellerStory != null &&
                                      seller.sellerStory!.isNotEmpty) ...[
                                    _SellerStorySection(
                                        story: seller.sellerStory!),
                                    SizedBox(height: isLargeTablet ? 12 : 16),
                                  ],
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'Mini prodavnica',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _ProductGrid(
                                    sellerId: seller.id,
                                    forceColumns: isDesktop ? 3 : 2,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isLargeTablet ? 12 : 16),
                            // Desno: recenzije
                            Expanded(
                              flex: isLargeTablet ? 4 : 2,
                              child: _ReviewsSection(sellerId: seller.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ] else ...[
                        // Mobilni / tablet – postojeći stacked layout
                        if (seller.farmGalleryUrls.isNotEmpty) ...[
                          SizedBox(height: isSmallTablet ? 14 : 16),
                          _FarmGallerySection(urls: seller.farmGalleryUrls),
                        ],
                        if (seller.sellerStory != null &&
                            seller.sellerStory!.isNotEmpty) ...[
                          SizedBox(height: isSmallTablet ? 14 : 16),
                          _SellerStorySection(story: seller.sellerStory!),
                        ],
                        SizedBox(height: isSmallTablet ? 14 : 16),
                        _ReviewsSection(sellerId: seller.id),
                        SizedBox(height: isSmallTablet ? 14 : 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Mini prodavnica',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ProductGrid(
                          sellerId: seller.id,
                          forceColumns: isSmallTablet ? 2 : null,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
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
    final following =
        await _favSellersService.isFollowing(user.id, widget.seller.id);
    if (mounted) {
      setState(() {
        _isFollowing = following;
        _checked = true;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      context.go('/login');
      return;
    }
    setState(() => _loading = true);
    await _favSellersService.toggleFollow(user.id, widget.seller.id);
    if (mounted) {
      setState(() {
        _isFollowing = !_isFollowing;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final seller = widget.seller;
    final cardPadding = Breakpoints.cardPadding(context);
    final avatarSize = Breakpoints.adaptiveDouble(
      context,
      phone: 80,
      smallTabletValue: 86,
      largeTabletValue: 92,
      desktop: 92,
    );
    final titleSize = Breakpoints.adaptiveDouble(
      context,
      phone: 24,
      smallTabletValue: 28,
      largeTabletValue: 30,
      desktop: 30,
    );
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    seller.farmName ?? 'Gazdinstvo',
                    textAlign: TextAlign.center,
                    style: Breakpoints.heroTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleLarge,
                    )?.copyWith(fontSize: titleSize),
                  ),
                ),
                if (seller.isVerified) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Proveren prodavac',
                    child: Icon(Icons.verified,
                        color: Theme.of(context).colorScheme.primary, size: 20),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                seller.profileImageUrl != null
                    ? ClipOval(
                        child: AppNetworkImage.profileLarge(
                          imageUrl: seller.profileImageUrl!,
                          width: avatarSize,
                          height: avatarSize,
                        ),
                      )
                    : CircleAvatar(
                        radius: avatarSize / 2,
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(Icons.store,
                            size: avatarSize / 2, color: Colors.grey.shade600),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (seller.createdAt != null) ...[
                        Text(
                          'Član od ${DateFormat('dd.MM.yyyy', 'sr').format(seller.createdAt!)}',
                          style: Breakpoints.supportingTextStyle(
                            context,
                            Theme.of(context).textTheme.bodySmall,
                            phone: 13,
                            largeTabletValue: 14,
                            desktop: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (seller.location != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(seller.location!,
                                style: Breakpoints.supportingTextStyle(
                                  context,
                                  Theme.of(context).textTheme.bodyMedium,
                                  phone: 14,
                                  largeTabletValue: 14,
                                  desktop: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.2,
                                )),
                          ],
                        ),
                      ],
                      FutureBuilder<SellerStatsModel>(
                        future: ReviewsService().getSellerStats(seller.id),
                        builder: (context, snap) {
                          final stats = snap.data;
                          if (stats == null) {
                            return const SizedBox.shrink();
                          }

                          final response = stats.responseLabel;
                          final orders = stats.ordersCount;

                          String? deliveredLabel() {
                            final n = orders;
                            if (n <= 0) return null;
                            if (n == 1) return '1 isporuka';
                            if (n >= 2 && n <= 4) return '$n isporuke';
                            return '$n isporuka';
                          }

                          if ((response == null || response.isEmpty) &&
                              (deliveredLabel() == null)) {
                            return const SizedBox.shrink();
                          }

                          final delivered = deliveredLabel();

                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (response != null && response.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.schedule,
                                          size: 14,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        response,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (delivered != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.local_shipping_outlined,
                                          size: 14,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        delivered,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
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
                                Icon(Icons.people_outline,
                                    size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  '$count pratilac${count == 1 ? '' : 'a'}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500),
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isFollowing ? 'Ne prati' : 'Prati'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerLoyaltyStats {
  final int repeatOrders;
  final int repeatBuyers;

  const _SellerLoyaltyStats({
    required this.repeatOrders,
    required this.repeatBuyers,
  });

  factory _SellerLoyaltyStats.fromJson(Map<String, dynamic> json) {
    return _SellerLoyaltyStats(
      repeatOrders: (json['repeat_orders'] as num?)?.toInt() ?? 0,
      repeatBuyers: (json['repeat_buyers'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasAnyLoyalty => repeatOrders > 0 && repeatBuyers > 0;
}

class _SellerSafetyStrip extends StatefulWidget {
  final UserModel seller;

  const _SellerSafetyStrip({required this.seller});

  @override
  State<_SellerSafetyStrip> createState() => _SellerSafetyStripState();
}

class _SellerSafetyStripState extends State<_SellerSafetyStrip> {
  late final Future<_SellerLoyaltyStats> _loyaltyFuture = _loadLoyalty();

  Future<_SellerLoyaltyStats> _loadLoyalty() async {
    try {
      final client = Supabase.instance.client;
      final result = await client.rpc(
        'get_seller_loyalty_stats',
        params: {'p_seller_id': widget.seller.id},
      );
      if (result == null) {
        return const _SellerLoyaltyStats(repeatOrders: 0, repeatBuyers: 0);
      }
      final map = result is Map<String, dynamic>
          ? result
          : Map<String, dynamic>.from(result as Map);
      return _SellerLoyaltyStats.fromJson(map);
    } catch (_) {
      return const _SellerLoyaltyStats(repeatOrders: 0, repeatBuyers: 0);
    }
  }

  static String? _repeatLabel(_SellerLoyaltyStats stats) {
    if (!stats.hasAnyLoyalty) return null;
    final n = stats.repeatOrders;
    if (n == 1) return '1 ponovljena kupovina od istih kupaca';
    if (n >= 2 && n <= 4) return '$n ponovljene kupovine od istih kupaca';
    return '$n ponovljenih kupovina od istih kupaca';
  }

  @override
  Widget build(BuildContext context) {
    final seller = widget.seller;
    final isVerified = seller.isVerified;

    return FutureBuilder<_SellerLoyaltyStats>(
      future: _loyaltyFuture,
      builder: (context, snap) {
        final stats = snap.data;
        final repeat = stats != null ? _repeatLabel(stats) : null;

        if (!isVerified && repeat == null) {
          return const SizedBox.shrink();
        }

        final children = <Widget>[];

        if (isVerified) {
          children.add(
            _ReputationItem(
              icon: Icons.verified,
              iconColor: Theme.of(context).colorScheme.primary,
              title: 'Provereno gazdinstvo',
              value: 'Dokumenta i podaci su provereni',
            ),
          );
        }

        if (repeat != null) {
          children.add(
            _ReputationItem(
              icon: Icons.repeat_outlined,
              iconColor: Colors.green.shade700,
              title: 'Lojalni kupci',
              value: repeat,
            ),
          );
        }

        if (children.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: w,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ReputationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _ReputationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _launchCall(BuildContext context, String? phone) async {
  final rawPhone = phone?.trim() ?? '';
  if (rawPhone.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broj telefona nije dostupan.')),
      );
    }
    return;
  }
  final normalized = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (normalized.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broj telefona nije validan.')),
      );
    }
    return;
  }
  final uri = Uri(scheme: 'tel', path: normalized);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pozivanje nije podržano na ovom uređaju.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nije moguće pokrenuti poziv.')),
      );
    }
  }
}

class _CallButton extends StatelessWidget {
  final UserModel seller;

  const _CallButton({required this.seller});

  @override
  Widget build(BuildContext context) {
    final phone = seller.phone?.trim();
    if (phone == null || phone.isEmpty) return const SizedBox.shrink();

    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(48, 48),
      ),
      onPressed: () => _launchCall(context, seller.phone),
      icon: const Icon(Icons.phone, size: 18),
      label: const Text('Pozovi'),
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
        padding: EdgeInsets.all(
          Breakpoints.adaptiveDouble(
            context,
            phone: 16,
            smallTabletValue: 17,
            largeTabletValue: 18,
            desktop: 18,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O gazdinstvu',
                style: Breakpoints.sectionTitleStyle(
                  context,
                  Theme.of(context).textTheme.titleMedium,
                )),
            const SizedBox(height: 8),
            Text(
              story,
              style: Breakpoints.supportingTextStyle(
                context,
                Theme.of(context).textTheme.bodyMedium,
                phone: 14,
                largeTabletValue: 15,
                desktop: 15,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
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
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Galerija',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isLargeTablet ? 20 : null,
                )),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final galleryHeight = Breakpoints.adaptiveDouble(
              context,
              phone: 168,
              smallTabletValue: 188,
              largeTabletValue: 220,
              desktop: 240,
            );
            final tileWidth = constraints.maxWidth *
                (Breakpoints.isDesktop(context)
                    ? 0.9
                    : (isLargeTablet ? 0.88 : (isSmallTablet ? 0.86 : 0.84)));

            return SizedBox(
              height: galleryHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: urls.length,
                itemBuilder: (_, i) => Padding(
                  padding:
                      EdgeInsets.only(right: i == urls.length - 1 ? 0 : 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: urls[i],
                      width: tileWidth,
                      memCacheWidth: 900,
                      memCacheHeight: 600,
                      height: galleryHeight,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              ),
            );
          },
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
  bool _expanded = true;

  void _refresh() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final canReview =
        user != null && !user.isGuest && user.id != widget.sellerId;
    final isSeller =
        user != null && !user.isGuest && user.id == widget.sellerId;
    final isWide =
        Breakpoints.isLargeTablet(context) || Breakpoints.isDesktop(context);
    final cardPadding = Breakpoints.adaptiveDouble(
      context,
      phone: 16,
      largeTabletValue: 18,
      desktop: 18,
    );

    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(_refreshKey),
      future: Future.wait([
        ReviewsService().getSellerStats(widget.sellerId),
        ReviewsService().getReviewsForSeller(widget.sellerId),
        if (canReview)
          ReviewsService().getReviewableOrder(user.id, widget.sellerId),
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
      builder: (_) => _AllReviewsSheet(
        reviews: reviews,
        isSeller: isSeller,
        onRefresh: _refresh,
        buyerNames: buyerNames,
      ),
    );
  }
}

// ─── Bottom sheet: sve recenzije ──────────────────────────────────────────────

class _AllReviewsSheet extends StatefulWidget {
  final List<ReviewModel> reviews;
  final bool isSeller;
  final VoidCallback onRefresh;
  final Map<String, String> buyerNames;

  const _AllReviewsSheet({
    required this.reviews,
    required this.isSeller,
    required this.onRefresh,
    required this.buyerNames,
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

// ─── Tagovi prodavca ──────────────────────────────────────────────────────────

class _SellerTagsRow extends StatelessWidget {
  final List<String> tags;
  const _SellerTagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    final normalized =
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
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
                tooltip =
                    'Prodavac organizuje dostavu u vaš grad (ili dogovorom).';
              }
              return Tooltip(
                message: tooltip,
                child: Chip(
                  avatar: Icon(icon, size: 16, color: Colors.white),
                  label: Text(
                    t,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  backgroundColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

class _ProductGrid extends StatefulWidget {
  final String sellerId;
  final int? forceColumns;

  const _ProductGrid({required this.sellerId, this.forceColumns});

  @override
  State<_ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<_ProductGrid> {
  Stream<List<ProductModel>>? _productsStream;
  String? _lastSellerId;
  late final Future<Map<String, ({double avg, int count})>> _ratingsFuture =
      ProductsService().getProductRatings();

  void _ensureStream(String sellerId) {
    if (_lastSellerId == sellerId) return;
    _lastSellerId = sellerId;
    _productsStream = ProductsService().getProductsBySeller(sellerId);
  }

  @override
  Widget build(BuildContext context) {
    _ensureStream(widget.sellerId);
    return StreamBuilder<List<ProductModel>>(
      stream: _productsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SellerProductListSkeleton(itemCount: 3);
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Ovaj prodavac još nema proizvoda',
              subtitle: 'Pogledajte druge proizvođače ili se vratite kasnije.',
              ctaLabel: 'Pretraži proizvode',
              ctaIcon: Icons.search,
              onCtaPressed: () => context.go('/'),
            ),
          );
        }
        return FutureBuilder<Map<String, ({double avg, int count})>>(
          future: _ratingsFuture,
          builder: (context, ratingsSnap) {
            final ratings = ratingsSnap.data ?? {};
            return LayoutBuilder(
              builder: (context, constraints) {
                final isLargeTablet = Breakpoints.isLargeTablet(context);
                final isSmallTablet = Breakpoints.isSmallTablet(context);
                final crossAxisCount = widget.forceColumns ??
                    Breakpoints.productGridColumns(context);
                const gridSpacing = 6.0;
                final tileWidth = (constraints.maxWidth -
                        (crossAxisCount - 1) * gridSpacing) /
                    crossAxisCount;
                final imageHeight = (tileWidth * 0.78).clamp(
                  isLargeTablet ? 132.0 : 120.0,
                  isLargeTablet ? 200.0 : (isSmallTablet ? 194.0 : 190.0),
                );
                final tileHeight = imageHeight +
                    (isLargeTablet ? 178.0 : (isSmallTablet ? 184.0 : 190.0));
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: tileHeight,
                    crossAxisSpacing: gridSpacing,
                    mainAxisSpacing: gridSpacing,
                  ),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final p = list[i];
                    final canAddToOrder = () {
                      final u = ctx.read<AppState>().user;
                      return u != null &&
                          !u.isGuest &&
                          u.id != widget.sellerId &&
                          p.isAvailable;
                    }();
                    final ratingStats = ratings[p.id];
                    return Selector<FavoritesProvider, bool>(
                      selector: (_, fav) => fav.isFavorite(p.id),
                      builder: (_, isFavorite, __) {
                        final user = ctx.read<AppState>().user;
                        final canFavorite = user != null && !user.isGuest;
                        final favorites = ctx.read<FavoritesProvider>();
                        return ProductGridTile(
                          product: p,
                          isFavorite: canFavorite ? isFavorite : null,
                          onFavoriteToggle: canFavorite
                              ? () => favorites.toggle(user.id, p.id)
                              : null,
                          onAddToOrder: canAddToOrder
                              ? () {
                                  showModalBottomSheet<void>(
                                    context: ctx,
                                    builder: (sheetContext) => _AddToOrderSheet(
                                      product: p,
                                      sellerId: widget.sellerId,
                                      cart: ctx.read<CartProvider>(),
                                      onAdded: () {
                                        if (!ctx.mounted) return;
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                                'Proizvod je dodat u porudžbinu.'),
                                            action: SnackBarAction(
                                              label: 'Pregled',
                                              onPressed: () => ctx.push(
                                                  '/checkout-seller/${widget.sellerId}'),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }
                              : null,
                          avgRating: ratingStats?.avg,
                          reviewCount: ratingStats?.count,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
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
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
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
                          _quantity = next < p.minOrderKg
                              ? p.minOrderKg
                              : next.clamp(p.minOrderKg, max);
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
                    : () => setState(() => _quantity =
                        (_quantity + step).clamp(p.minOrderKg, max)),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => withHaptic(() {
              widget.cart.addForSeller(
                sellerId: widget.sellerId,
                productId: p.id,
                quantity: _quantity,
              );
              Navigator.of(context).pop();
              widget.onAdded();
            }),
            child: const Text('Dodaj u porudžbinu'),
          ),
        ],
      ),
    );
  }
}

class _SellerOrderDraftBar extends StatelessWidget {
  final String sellerId;
  final UserModel seller;

  const _SellerOrderDraftBar({required this.sellerId, required this.seller});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AppState, UserModel?>((s) => s.user);
    final canContact = user != null && !user.isGuest && user.id != sellerId;

    final draft = context.select<CartProvider, Map<String, double>>(
      (cart) => cart.getSellerDraft(sellerId),
    );
    final hasDraft = draft.isNotEmpty;

    if (!canContact && !hasDraft) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasDraft) ...[
              Text(
                '${draft.length} proizvoda u porudžbini kod ovog prodavca',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              FutureBuilder<List<({ProductModel product, double quantity})>>(
                future:
                    context.read<CartProvider>().getProductsBySeller(sellerId),
                builder: (_, snap) {
                  final items = snap.data ?? [];
                  if (items.isEmpty) return const SizedBox.shrink();
                  final preview =
                      items.take(3).map((e) => e.product.name).join(', ');
                  final suffix =
                      items.length > 3 ? ' +${items.length - 3}' : '';
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
              if (canContact) const SizedBox(height: 8),
            ],
            if (canContact)
              Builder(
                builder: (context) {
                  final hasPhone = seller.phone?.trim().isNotEmpty == true;
                  final chatButton = OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        final convId = await ChatService()
                            .getOrCreateConversation(user.id, sellerId);
                        if (context.mounted) context.push('/chat/$convId');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Greška: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Pošalji poruku'),
                  );
                  if (hasPhone) {
                    return Row(
                      children: [
                        Expanded(child: _CallButton(seller: seller)),
                        const SizedBox(width: 8),
                        Expanded(child: chatButton),
                      ],
                    );
                  }
                  return chatButton;
                },
              ),
          ],
        ),
      ),
    );
  }
}
