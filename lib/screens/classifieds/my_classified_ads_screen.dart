import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/classified_ad_model.dart';
import '../../models/classified_seller_stats_model.dart';
import '../../providers/app_state.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/classifieds/seller_analytics_summary_card.dart';

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

  Future<void> _toggleFeatured(ClassifiedAdModel ad) async {
    final nextVal = !ad.isFeatured;
    try {
      await _service.updateAdFeatured(
        ad.id,
        nextVal,
        until: nextVal ? DateTime.now().add(const Duration(days: 30)) : null,
      );
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextVal
                ? 'Oglas je uspešno istaknut na vrhu pretrage!'
                : 'Isticanje oglasa je uklonjeno.'),
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

          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
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
                              ? CachedNetworkImage(
                                  imageUrl: ad.images.first,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  placeholder: (c, url) => Container(
                                    width: 72,
                                    height: 72,
                                    color: colorScheme.surfaceContainerHighest,
                                  ),
                                  errorWidget: (c, url, err) => Container(
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
                                      tooltip: ad.isCurrentlyFeatured ? 'Ukloni isticanje' : 'Istakni oglas',
                                      icon: Icon(
                                        ad.isCurrentlyFeatured ? Icons.star_rounded : Icons.star_outline_rounded,
                                        color: ad.isCurrentlyFeatured ? const Color(0xFFD97706) : colorScheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                      onPressed: () => _toggleFeatured(ad),
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
