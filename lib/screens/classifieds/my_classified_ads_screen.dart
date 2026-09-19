import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/classified_ad_model.dart';
import '../../models/classified_seller_stats_model.dart';
import '../../providers/app_state.dart';
import '../../core/responsive.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/classifieds/seller_analytics_summary_card.dart';
import '../../core/design_system.dart';

class MyClassifiedAdsScreen extends StatefulWidget {
  const MyClassifiedAdsScreen({super.key});

  @override
  State<MyClassifiedAdsScreen> createState() => _MyClassifiedAdsScreenState();
}

class _MyClassifiedAdsScreenState extends State<MyClassifiedAdsScreen> {
  late ClassifiedsService _service;
  late Future<List<ClassifiedAdModel>> _adsFuture;
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
    }
  }

  Future<void> _deleteAd(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje oglasa'),
        content: const Text('Da li ste sigurni da želite da obrišete ovaj oglas?'),
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

  void _showFeaturedInfo(ClassifiedAdModel ad) {
    if (ad.isCurrentlyFeatured) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusL),
          ),
          title: const Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text('Istaknut oglas'),
            ],
          ),
          content: const Text(
            'Ovaj oglas je trenutno istaknut na vrhu pretrage.\n\nŽelite li da uklonite isticanje?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zadrži'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _removeFeatured(ad);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Ukloni isticanje'),
            ),
          ],
        ),
      );
      return;
    }

    _showFeaturedComingSoon(context);
  }

  void _showFeaturedComingSoon(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);

    Widget content(BuildContext ctx) {
      final theme = Theme.of(ctx);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFD97706),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'USKORO',
                style: TextStyle(
                  color: Color(0xFFD97706),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Isticanje oglasa na vrhu',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Želite da vaš oglas vidi do 5x više kupaca?\n\nIstaknuti oglasi se prikazuju na samom vrhu kategorije i početne strane sa prepoznatljivim zlatnim bedžom.\n\nOva mogućnost će biti dostupna u narednom ažuriranju sa uvođenjem promotivnih paketa.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDesign.radiusM),
                  ),
                ),
                child: const Text(
                  'Razumem',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusXL),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: content(ctx),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDesign.radiusXL),
          ),
        ),
        builder: (ctx) => SafeArea(
          child: content(ctx),
        ),
      );
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
        appBar: AppBar(title: const Text('Moji oglasi')),
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
        ],
      ),
      body: FutureBuilder<List<ClassifiedAdModel>>(
        future: _adsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              subtitle: 'Objavite mašinu, alat, vozilo ili bilo koji drugi predmet besplatno.',
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
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: Breakpoints.isTabletOrLarger(context) ? 16 : 0,
                    vertical: 8,
                  ),
                  itemCount: list.length + 1,
                  itemBuilder: (ctx, i) {
                if (i == 0) {
                  if (_statsFuture != null) {
                    return FutureBuilder<ClassifiedSellerStatsModel>(
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
                    );
                  }
                  return const SizedBox.shrink();
                }

                final ad = list[i - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Card(
                  elevation: 1,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: ad.isCurrentlyFeatured
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.8)
                          : colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: ad.isCurrentlyFeatured ? 1.5 : 1.0,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => context.push('/classifieds/ad/${ad.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail prve slike
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ad.images.isNotEmpty
                              ? AppNetworkImage.thumbnail(
                                  imageUrl: ad.images.first,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  placeholder: Container(
                                    width: 72,
                                    height: 72,
                                    color: colorScheme.surfaceContainerHighest,
                                  ),
                                  errorWidget: Container(
                                    width: 72,
                                    height: 72,
                                    color: colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.broken_image, size: 32),
                                  ),
                                )
                              : Container(
                                  width: 72,
                                  height: 72,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.campaign_outlined,
                                    size: 32,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),

                        // Desna strana — status, naslov, meta, akcije
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Status bedž
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: ad.isSold
                                          ? Colors.grey.shade600
                                          : Colors.green.shade700,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      ad.isSold ? 'PRODATO' : 'AKTIVAN',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (ad.isCurrentlyFeatured) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD97706),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star_rounded, size: 11, color: Colors.white),
                                          SizedBox(width: 3),
                                          Text(
                                            'ISTAKNUTO',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (ad.isUrgent) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.bolt_rounded, size: 11, color: Colors.white),
                                          SizedBox(width: 2),
                                          Text(
                                            'HITNO',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
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
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Naslov
                              Text(
                                ad.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              // Lokacija i pregledi
                              Text(
                                '${ad.city} · ${ad.timeAgo}',
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              // Metrika angažovanosti kupaca
                              Row(
                                children: [
                                  _buildMetricBadge(
                                    icon: Icons.visibility_outlined,
                                    text: '${ad.viewsCount}',
                                    tooltip: 'Ukupno pregleda',
                                    color: const Color(0xFF0284C7),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMetricBadge(
                                    icon: Icons.phone_in_talk_outlined,
                                    text: '${ad.callClicksCount}',
                                    tooltip: 'Klikovi na telefon',
                                    color: const Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMetricBadge(
                                    icon: Icons.share_outlined,
                                    text: '${ad.sharesCount}',
                                    tooltip: 'Deljenja oglasa',
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              // Radnje
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!ad.isSold) ...[
                                    IconButton(
                                      tooltip: ad.isCurrentlyFeatured
                                          ? 'Istaknut oglas'
                                          : 'Istakni oglas (Uskoro)',
                                      icon: Icon(
                                        ad.isCurrentlyFeatured
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: ad.isCurrentlyFeatured
                                            ? const Color(0xFFD97706)
                                            : colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                        size: 20,
                                      ),
                                      onPressed: () => _showFeaturedInfo(ad),
                                    ),
                                    IconButton(
                                      tooltip: ad.isUrgent ? 'Ukloni hitnost' : 'Označi kao hitno',
                                      icon: Icon(
                                        ad.isUrgent ? Icons.bolt_rounded : Icons.bolt_outlined,
                                        color: ad.isUrgent ? const Color(0xFFDC2626) : colorScheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                      onPressed: () => _toggleUrgent(ad),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _markAsSold(ad.id),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Prodato',
                                          style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                  IconButton(
                                    tooltip: 'Pogledaj oglas',
                                    icon: const Icon(Icons.visibility_outlined, size: 20),
                                    onPressed: () => context.push('/classifieds/ad/${ad.id}'),
                                  ),
                                  IconButton(
                                    tooltip: 'Izmeni',
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20),
                                    onPressed: () async {
                                      await context
                                          .push('/classifieds/edit/${ad.id}');
                                      _load();
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Obriši',
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                    onPressed: () => _deleteAd(ad.id),
                                  ),
                                ],
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required String text,
    required String tooltip,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
