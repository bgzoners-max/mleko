import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/classified_ad_model.dart';
import '../../providers/app_state.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_retry.dart';

class MyClassifiedAdsScreen extends StatefulWidget {
  const MyClassifiedAdsScreen({super.key});

  @override
  State<MyClassifiedAdsScreen> createState() => _MyClassifiedAdsScreenState();
}

class _MyClassifiedAdsScreenState extends State<MyClassifiedAdsScreen> {
  final _service = ClassifiedsService();
  late Future<List<ClassifiedAdModel>> _adsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final user = context.read<AppState>().user;
    if (user != null) {
      setState(() {
        _adsFuture = _service.getUserAds(user.id);
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moji oglasi')),
        body: const Center(child: Text('Prijavite se da vidite svoje oglase.')),
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
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final ad = list[i];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Status bedž
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),

                        // Lokacija i pregledi
                        Text(
                          '${ad.city} · ${ad.viewsCount} pregleda · ${ad.timeAgo}',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                        const Divider(height: 20),

                        // Radnje
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!ad.isSold)
                              TextButton.icon(
                                onPressed: () => _markAsSold(ad.id),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Prodato', style: TextStyle(fontSize: 12)),
                              ),
                            IconButton(
                              tooltip: 'Izmeni',
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () async {
                                await context.push('/classifieds/edit/${ad.id}');
                                _load();
                              },
                            ),
                            IconButton(
                              tooltip: 'Obriši',
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _deleteAd(ad.id),
                            ),
                          ],
                        ),
                      ],
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
}
