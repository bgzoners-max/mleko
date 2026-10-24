import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/classified_ad_model.dart';
import '../../models/classified_seller_stats_model.dart';
import '../../providers/app_state.dart';
import '../../core/responsive.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/classifieds/featured_dialogs.dart';
import '../../widgets/classifieds/metric_badge.dart';
import '../../widgets/classifieds/seller_analytics_summary_card.dart';
import '../../widgets/skeletons/product_skeletons.dart';

class MyClassifiedAdsScreen extends StatefulWidget {
  const MyClassifiedAdsScreen({super.key});

  @override
  State<MyClassifiedAdsScreen> createState() => _MyClassifiedAdsScreenState();
}

class _MyClassifiedAdsScreenState extends State<MyClassifiedAdsScreen> {
  late ClassifiedsService _service;
  Future<List<ClassifiedAdModel>> _adsFuture = Future.value(const []);
  Future<ClassifiedSellerStatsModel>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _service = context.read<ClassifiedsService>();
    _load();
  }

  void _load() {
    final user = context.read<AppState>().user;
    if (user != null && !user.isGuest) {
      setState(() {
        _adsFuture = _service.getUserAds(user.id);
        _statsFuture = _service.getSellerStats(user.id);
      });
    } else {
      setState(() {
        _adsFuture = Future.value(const []);
        _statsFuture = null;
      });
    }
  }

  Future<void> _deleteAd(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje oglasa'),
        content:
            const Text('Da li ste sigurni da želite da obrišete ovaj oglas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteAd(id);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oglas je obrisan.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Greška pri brisanju: $e')),
          );
        }
      }
    }
  }

  Future<void> _markAsSold(String id) async {
    try {
      await _service.markAsSold(id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oglas je označen kao prodat.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
        );
      }
    }
  }

  Future<void> _removeFeatured(ClassifiedAdModel ad) async {
    try {
      await _service.updateAdFeatured(
        ad.id,
        false,
        until: null,
      );
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Isticanje oglasa je uklonjeno.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
        );
      }
    }
  }


  Future<void> _toggleUrgent(ClassifiedAdModel ad) async {
    final nextVal = !ad.isUrgent;
    try {
      await _service.updateAdUrgent(ad.id, nextVal);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextVal
                ? 'Oglas je označen kao HITAN!'
                : 'Oznaka hitnosti je uklonjena.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/classifieds'),
          title: const Text('Moji oglasi'),
          actions: const [AppHomeButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AppEmptyState(
              icon: Icons.lock_outline,
              title: 'Prijavite se na nalog',
              subtitle:
                  'Pregled i upravljanje sopstvenim oglasima dostupni su samo prijavljenim korisnicima.',
              ctaLabel: 'Prijavi se',
              ctaIcon: Icons.login,
              onCtaPressed: () => context.push('/login'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/classifieds'),
        title: const Text('Moji oglasi'),
        actions: [
          IconButton(
            tooltip: 'Postavi oglas',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await context.push('/classifieds/new');
              _load();
            },
          ),
          const AppHomeButton(),
        ],
      ),
      body: FutureBuilder<List<ClassifiedAdModel>>(
        future: _adsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ProductListSkeleton(itemCount: 4);
          }

          if (snapshot.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju vaših oglasa.',
              onRetry: _load,
            );
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return AppEmptyState(
              icon: Icons.campaign_outlined,
              title: 'Nemate postavljenih oglasa',
              subtitle:
                  'Objavite mašinu, alat, vozilo ili bilo koji drugi predmet besplatno.',
              ctaLabel: 'Postavi prvi oglas',
              ctaIcon: Icons.add,
              onCtaPressed: () async {
                await context.push('/classifieds/new');
                _load();
              },
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Breakpoints.maxContentWidth(context),
              ),
              child: RefreshIndicator(
                onRefresh: () async => _load(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (_statsFuture != null)
                          SliverToBoxAdapter(
                            child: FutureBuilder<ClassifiedSellerStatsModel>(
                              future: _statsFuture,
                              builder: (context, statsSnap) {
                                final stats = statsSnap.data;
                                if (stats == null || !stats.hasAds) {
                                  return const SizedBox.shrink();
                                }
                                return SellerAnalyticsSummaryCard(
                                  stats: stats,
                                  onRefresh: _load,
                                );
                              },
                            ),
                          ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 10 : 6,
                            vertical: 6,
                          ),
                          sliver: isWide
                              ? SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    mainAxisExtent: 144,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, i) => _buildCompactAdCard(
                                        ctx, list[i], colorScheme),
                                    childCount: list.length,
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, i) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: _buildCompactAdCard(
                                          ctx, list[i], colorScheme),
                                    ),
                                    childCount: list.length,
                                  ),
                                ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 24),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactAdCard(
    BuildContext context,
    ClassifiedAdModel ad,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0.5,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: ad.isCurrentlyFeatured
              ? const Color(0xFFF59E0B)
              : colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: ad.isCurrentlyFeatured ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/classifieds/ad/${ad.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ad.images.isNotEmpty
                        ? AppNetworkImage.thumbnail(
                            imageUrl: ad.images.first,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              width: 64,
                              height: 64,
                              color: colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: Container(
                              width: 64,
                              height: 64,
                              color: colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image, size: 24),
                            ),
                          )
                        : Container(
                            width: 64,
                            height: 64,
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.campaign_outlined,
                              size: 26,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: ad.isSold
                                    ? Colors.grey.shade600
                                    : Colors.green.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ad.isSold ? 'PRODATO' : 'AKTIVAN',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (ad.isCurrentlyFeatured) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded,
                                        size: 10, color: Colors.white),
                                    SizedBox(width: 2),
                                    Text(
                                      'ISTAKNUTO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (ad.isUrgent) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt_rounded,
                                        size: 10, color: Colors.white),
                                    SizedBox(width: 1),
                                    Text(
                                      'HITNO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              ad.priceFormatted,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ad.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ad.city} · ${ad.timeAgo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            MetricBadge(
                              icon: Icons.visibility_outlined,
                              text: '${ad.viewsCount}',
                              tooltip: 'Pregleda',
                              color: const Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 6),
                            MetricBadge(
                              icon: Icons.phone_in_talk_outlined,
                              text: '${ad.callClicksCount}',
                              tooltip: 'Poziva',
                              color: const Color(0xFF059669),
                            ),
                            const SizedBox(width: 6),
                            MetricBadge(
                              icon: Icons.share_outlined,
                              text: '${ad.sharesCount}',
                              tooltip: 'Deljenja',
                              color: const Color(0xFF8B5CF6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(height: 1, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!ad.isSold) ...[
                    if (ad.isCurrentlyFeatured)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 26, minHeight: 26),
                        tooltip: 'Istaknut oglas (Ukloni)',
                        icon: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFD97706),
                          size: 17,
                        ),
                        onPressed: () => showFeaturedInfo(
                            context, ad, () => _removeFeatured(ad)),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 26, minHeight: 26),
                      tooltip:
                          ad.isUrgent ? 'Ukloni hitnost' : 'Označi kao hitno',
                      icon: Icon(
                        ad.isUrgent
                            ? Icons.bolt_rounded
                            : Icons.bolt_outlined,
                        color: ad.isUrgent
                            ? const Color(0xFFDC2626)
                            : colorScheme.onSurfaceVariant,
                        size: 17,
                      ),
                      onPressed: () => _toggleUrgent(ad),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 0),
                        minimumSize: const Size(0, 26),
                      ),
                      onPressed: () => _markAsSold(ad.id),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 13),
                          SizedBox(width: 2),
                          Text('Prodato', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    tooltip: 'Pogledaj oglas',
                    icon: const Icon(Icons.visibility_outlined, size: 17),
                    onPressed: () =>
                        context.push('/classifieds/ad/${ad.id}'),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    tooltip: 'Izmeni',
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    onPressed: () async {
                      await context.push('/classifieds/edit/${ad.id}');
                      _load();
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    tooltip: 'Obriši',
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 17),
                    onPressed: () => _deleteAd(ad.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
