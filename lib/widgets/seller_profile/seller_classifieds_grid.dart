import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../models/classified_ad_model.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/classifieds/classified_ad_card.dart';

class SellerClassifiedsGrid extends StatefulWidget {
  final String sellerId;
  final int? forceColumns;

  const SellerClassifiedsGrid({
    super.key,
    required this.sellerId,
    this.forceColumns,
  });

  @override
  State<SellerClassifiedsGrid> createState() => _SellerClassifiedsGridState();
}

class _SellerClassifiedsGridState extends State<SellerClassifiedsGrid> {
  Future<List<ClassifiedAdModel>>? _adsFuture;
  String? _lastSellerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureFuture(widget.sellerId);
  }

  @override
  void didUpdateWidget(covariant SellerClassifiedsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sellerId != widget.sellerId) {
      _ensureFuture(widget.sellerId, force: true);
    }
  }

  void _ensureFuture(String sellerId, {bool force = false}) {
    if (!force && _lastSellerId == sellerId && _adsFuture != null) return;
    _lastSellerId = sellerId;
    _adsFuture = context.read<ClassifiedsService>().getUserAds(sellerId);
  }

  @override
  Widget build(BuildContext context) {
    _ensureFuture(widget.sellerId);

    return FutureBuilder<List<ClassifiedAdModel>>(
      future: _adsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: AppEmptyState(
              icon: Icons.error_outline,
              title: 'Greška pri učitavanju oglasa',
              subtitle: 'Došlo je do problema. Pokušajte ponovo.',
              ctaLabel: 'Osveži',
              ctaIcon: Icons.refresh,
              onCtaPressed: () => setState(() {
                _ensureFuture(widget.sellerId, force: true);
              }),
            ),
          );
        }

        final allAds = snapshot.data ?? [];
        // Prikazujemo aktivne oglase posetiocima
        final activeAds = allAds.where((ad) => ad.status == 'active').toList();

        if (activeAds.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: AppEmptyState(
              icon: Icons.campaign_outlined,
              title: 'Nema aktivnih malih oglasa',
              subtitle: 'Ovaj oglašivač trenutno nema objavljenih malih oglasa.',
              ctaLabel: 'Pretraži sve oglase',
              ctaIcon: Icons.search,
              onCtaPressed: () => context.go('/classifieds'),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = widget.forceColumns ??
                (Breakpoints.isDesktop(context)
                    ? 3
                    : (Breakpoints.isSmallTablet(context) ? 2 : 1));

            if (crossAxisCount == 1) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: activeAds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => ClassifiedAdCard(ad: activeAds[i]),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: 310,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: activeAds.length,
              itemBuilder: (ctx, i) => ClassifiedAdCard(ad: activeAds[i]),
            );
          },
        );
      },
    );
  }
}
