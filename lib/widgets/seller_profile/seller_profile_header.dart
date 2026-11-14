import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/profile_display_names.dart';
import '../../core/responsive.dart';
import '../../models/seller_stats_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import 'package:mleko/services/services.dart';
import '../../widgets/app_network_image.dart';
import '../app_share_sheet.dart';
import '../common/verified_badge.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPhone = Breakpoints.isPhone(context);

    final avatarSize = isPhone ? 64.0 : 74.0;
    final displayName = resolveProfileDisplayName(
      seller.farmName,
      seller.displayName,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF2B3A2E) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1A241C) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Profilna slika / Avatar
                seller.profileImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AppNetworkImage.profileLarge(
                          imageUrl: seller.profileImageUrl!,
                          width: avatarSize,
                          height: avatarSize,
                        ),
                      )
                    : Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A27)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2C4A35)
                                : const Color(0xFFC8E6C9),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          size: avatarSize * 0.48,
                          color: isDark
                              ? const Color(0xFF81C784)
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                const SizedBox(width: 14),

                // 2. Glavni podaci: Ime, bedževi i meta podaci
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ime prodavca + bedževi
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: isPhone ? 18 : 21,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1B201C),
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (seller.isVerified)
                            Tooltip(
                              message: 'Proveren prodavac',
                              child: Icon(
                                Icons.verified,
                                color: Theme.of(context).colorScheme.primary,
                                size: 18,
                              ),
                            ),
                          if (seller.isRegisteredProducer)
                            VerifiedBadge(
                              size: isPhone ? 28 : 32,
                              tooltip: (seller.pib != null &&
                                      seller.pib!.isNotEmpty)
                                  ? 'PIB: ${seller.pib}'
                                  : ((seller.bpgMasked != null &&
                                          seller.bpgMasked!.isNotEmpty)
                                      ? 'BPG: ${seller.bpgMasked}'
                                      : 'Registrovano poljoprivredno gazdinstvo'),
                            ),
                        ],
                      ),
                      if (seller.isRegisteredProducer) ...[
                        const SizedBox(height: 3),
                        Text(
                          seller.legalType == 'company' ||
                                  (seller.pib != null && seller.pib!.isNotEmpty)
                              ? 'Registrovani proizvođač (PIB)'
                              : 'Registrovano poljoprivredno gazdinstvo',
                          style: TextStyle(
                            fontSize: isPhone ? 12 : 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF81C784)
                                : const Color(0xFF2E7D32),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),

                      // Meta informacije: Lokacija, Član od, Ocene, Isporuke
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (seller.location != null &&
                              seller.location!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  seller.location!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          if (seller.createdAt != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Član od ${DateFormat('dd.MM.yyyy', 'sr').format(seller.createdAt!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          FutureBuilder<int>(
                            future: _followersFuture,
                            builder: (_, snap) {
                              final count = snap.data ?? 0;
                              if (count == 0) return const SizedBox.shrink();
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 14,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$count pratilac${count == 1 ? '' : 'a'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          FutureBuilder<SellerStatsModel>(
                            future: context
                                .read<ReviewsService>()
                                .getSellerStats(seller.id),
                            builder: (context, snap) {
                              final stats = snap.data;
                              if (stats == null) return const SizedBox.shrink();
                              final orders = stats.ordersCount;
                              if (orders <= 0) return const SizedBox.shrink();
                              final delivered = orders == 1
                                  ? '1 isporuka'
                                  : (orders <= 4
                                      ? '$orders isporuke'
                                      : '$orders isporuka');
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 14,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    delivered,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Akcije desno na tablet/desktop ekranima: Zaprati + Podeli profil
                if (!isPhone) ...[
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_checked) ...[
                        FilledButton.tonalIcon(
                          onPressed: _loading ? null : _toggleFollow,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: _loading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  _isFollowing
                                      ? Icons.check_rounded
                                      : Icons.person_add_outlined,
                                  size: 16,
                                ),
                          label: Text(_isFollowing ? 'Pratim' : 'Zaprati'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: () => withHaptic(
                            () => shareSellerProfile(context, seller)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: Icon(Icons.adaptive.share, size: 16),
                        label: const Text('Podeli profil'),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // Ako je telefon: dugme za praćenje + deljenje profila idu ispod
            if (isPhone) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_checked) ...[
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _loading ? null : _toggleFollow,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: _loading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _isFollowing
                                    ? Icons.check_rounded
                                    : Icons.person_add_outlined,
                                size: 16,
                              ),
                        label: Text(
                            _isFollowing ? 'Pratim' : 'Zaprati gazdinstvo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: _checked ? 0 : 1,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          withHaptic(() => shareSellerProfile(context, seller)),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(Icons.adaptive.share, size: 16),
                      label: Text(_checked ? 'Podeli' : 'Podeli profil'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
