import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/seller_stats_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import 'package:mleko/services/services.dart';

import '../../core/responsive.dart';
import '../../widgets/app_network_image.dart';

class SellerProfileHeader extends StatefulWidget {
  final UserModel seller;

  const SellerProfileHeader({super.key, required this.seller});

  @override
  State<SellerProfileHeader> createState() => _SellerProfileHeaderState();
}

class _SellerProfileHeaderState extends State<SellerProfileHeader> {
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
                        future: context.read<ReviewsService>().getSellerStats(seller.id),
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
