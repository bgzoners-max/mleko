import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design_system.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/classifieds_provider.dart';
import '../../utils/animations.dart';

/// Inspirativan, topao i moderan Desktop Hero Banner za Domaći Market.
///
/// Prikazuje:
/// 1. Autentičnu seosku fotografiju u pozadini sa toplim šumskim prelivom
/// 2. Eyebrow bedž sa garancijom domaćeg porekla
/// 3. Zanatski Bitter naslov i podnaslov misije platforme
/// 4. Primarna CTA dugmad (Istraži hranu, Mali oglasi, Mapa gazdinstava)
/// 5. 3 ključna stuba poverenja (100% Prirodno, Direktno od Proizvođača, Dostava/Preuzimanje)
/// 6. Brze tagove / prečice za najtraženije domaće proizvode
class DesktopHeroBanner extends StatelessWidget {
  final VoidCallback? onExploreFood;
  final VoidCallback? onExploreClassifieds;
  final ValueChanged<String>? onSearchTag;

  const DesktopHeroBanner({
    super.key,
    this.onExploreFood,
    this.onExploreClassifieds,
    this.onSearchTag,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompactDesktop = width < 1280;

    return FadeInSlide(
      delay: const Duration(milliseconds: 100),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AmazonColors.getBorder(context),
            width: 1.2,
          ),
          boxShadow: AmazonColors.getCardShadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. Pozadinska fotografija srpskog gazdinstva
            Positioned.fill(
              child: Image.asset(
                'assets/images/hero_farm_banner.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AmazonColors.darkNavy,
                ),
              ),
            ),

            // 2. Višeslojni preliv za maksimalnu čitljivost teksta
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xF7142419), // ~97% pokrivenosti levo
                      Color(0xE8142419), // ~91%
                      Color(0x9E142419), // ~62%
                      Color(0x28142419), // ~16% desno
                    ],
                    stops: [0.0, 0.40, 0.68, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Suptilni vertikalni preliv odozdo za stubove poverenja
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                    stops: const [0.65, 1.0],
                  ),
                ),
              ),
            ),

            // 4. Glavni sadržaj banera
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompactDesktop ? 24 : 32,
                vertical: isCompactDesktop ? 22 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Eyebrow bedž
                  _buildEyebrowBadge(),
                  const SizedBox(height: 12),

                  // Glavni zanatski Bitter naslov
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompactDesktop ? 620 : 720,
                    ),
                    child: Text(
                      'Direktno sa srpskih gazdinstava na vašu trpezu',
                      style: AppFonts.display(
                        Colors.white,
                        fontSize: isCompactDesktop ? 26 : 32,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Podnaslov sa misijom
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompactDesktop ? 560 : 660,
                    ),
                    child: Text(
                      'Pravi ukusi sela, bez industrijskih posrednika. Povežite se sa proverenim porodičnim proizvođačima, pčelarima, vodenicama i gazdinstvima širom Srbije.',
                      style: TextStyle(
                        fontSize: isCompactDesktop ? 13.5 : 14.5,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Akciona dugmad (CTA)
                  _buildActionButtons(context, isCompactDesktop: isCompactDesktop),
                  const SizedBox(height: 18),

                  // Brzi tagovi / popularno
                  _buildQuickTags(context),
                  const SizedBox(height: 22),

                  // Linija razdvajanja
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 16),

                  // 3 Stuba poverenja (Trust Badges)
                  _buildTrustBadges(context, isCompactDesktop: isCompactDesktop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Eyebrow Bedž ---
  Widget _buildEyebrowBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.eco_rounded,
            size: 14,
            color: AmazonColors.amberLight,
          ),
          const SizedBox(width: 6),
          Text(
            '100% PROVERENA DOMAĆA HRANA I GAZDINSTVA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  // --- Akciona Dugmad (CTA) ---
  Widget _buildActionButtons(
    BuildContext context, {
    required bool isCompactDesktop,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Primarno dugme: Istraži ponudu hrane
        ElevatedButton.icon(
          onPressed: () {
            if (onExploreFood != null) {
              onExploreFood!();
            } else {
              context.read<AppSettingsProvider>().setMarketMode(MarketMode.foodMarket);
              context.read<ClassifiedsProvider>().clearFilters();
              context.go('/');
            }
          },
          icon: const Icon(Icons.shopping_basket_outlined, size: 18),
          label: const Text(
            'Istraži ponudu hrane',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              letterSpacing: 0.1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AmazonColors.amber,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            padding: EdgeInsets.symmetric(
              horizontal: isCompactDesktop ? 18 : 22,
              vertical: isCompactDesktop ? 12 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Sekundarno dugme: Mali oglasi & poljoprivreda
        OutlinedButton.icon(
          onPressed: () {
            if (onExploreClassifieds != null) {
              onExploreClassifieds!();
            } else {
              context.read<AppSettingsProvider>().setMarketMode(MarketMode.classifieds);
              context.go('/classifieds');
            }
          },
          icon: const Icon(Icons.agriculture_outlined, size: 18),
          label: const Text(
            'Mali oglasi & mehanizacija',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            foregroundColor: Colors.white,
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.1,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isCompactDesktop ? 16 : 20,
              vertical: isCompactDesktop ? 12 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Tercijarno dugme: Mapa gazdinstava
        TextButton.icon(
          onPressed: () => context.push('/sellers-map'),
          icon: const Icon(
            Icons.map_outlined,
            size: 17,
            color: AmazonColors.amberLight,
          ),
          label: const Text(
            'Interaktivna mapa gazdinstava',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: AmazonColors.amberLight,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  // --- Brzi Tagovi / Popularne Pretrage ---
  Widget _buildQuickTags(BuildContext context) {
    final tags = [
      {'emoji': '🧀', 'label': 'Sir & Kajmak'},
      {'emoji': '🍯', 'label': 'Domaći med'},
      {'emoji': '🥩', 'label': 'Suvo meso & pršut'},
      {'emoji': '🫙', 'label': 'Zimnica & Ajvar'},
      {'emoji': '🍎', 'label': 'Domaće voće'},
      {'emoji': '🚜', 'label': 'Traktori & delovi'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Popularno:',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        ...tags.map((t) {
          final label = t['label']!;
          final emoji = t['emoji']!;

          return InkWell(
            onTap: () {
              if (onSearchTag != null) {
                onSearchTag!(label);
              } else {
                if (label.contains('Traktori')) {
                  context.read<AppSettingsProvider>().setMarketMode(MarketMode.classifieds);
                  context.read<ClassifiedsProvider>().search(label);
                  context.go('/classifieds');
                } else {
                  context.push('/search?q=${Uri.encodeComponent(label)}');
                }
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- 3 Stuba Poverenja (Trust Badges) ---
  Widget _buildTrustBadges(
    BuildContext context, {
    required bool isCompactDesktop,
  }) {
    final pillars = [
      _TrustPillarData(
        icon: Icons.eco_outlined,
        title: '100% Prirodno & Domaće',
        subtitle: 'Bez industrijskih dodataka, tradicija i pravi domaći ukus',
      ),
      _TrustPillarData(
        icon: Icons.handshake_outlined,
        title: 'Direktno od Proizvođača',
        subtitle: 'Bez posrednika – podrška vrednim porodičnim gazdinstvima',
      ),
      _TrustPillarData(
        icon: Icons.local_shipping_outlined,
        title: 'Dostava ili Lično Preuzimanje',
        subtitle: 'Sveže na kućnu adresu ili direktan dogovor sa domaćinom',
      ),
    ];

    if (isCompactDesktop) {
      return Column(
        children: pillars
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTrustItem(p),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: pillars.map((p) => Expanded(child: _buildTrustItem(p))).toList(),
    );
  }

  Widget _buildTrustItem(_TrustPillarData data) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AmazonColors.amber.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AmazonColors.amberLight.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: Icon(
              data.icon,
              size: 20,
              color: AmazonColors.amberLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustPillarData {
  final IconData icon;
  final String title;
  final String subtitle;

  _TrustPillarData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
