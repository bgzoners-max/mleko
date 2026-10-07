import 'package:flutter/material.dart';

import '../../core/design_system.dart';
import '../../core/responsive.dart';
import '../../models/classified_ad_model.dart';

/// Prikazuje dijalog o istaknutom oglasu — dio ekrana MyClassifiedAdsScreen.
void showFeaturedInfo(BuildContext context, ClassifiedAdModel ad, void Function() onRemoveFeatured) {
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
              onRemoveFeatured();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ukloni isticanje'),
          ),
        ],
      ),
    );
    return;
  }

  featuredComingSoonDialog(context);
}

/// Dijalog „USKORO“ za približavanje isticanje oglasa — izvučen iz ekrana.
void featuredComingSoonDialog(BuildContext context) {
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
            'Želite da vaš oglas vidi do 5x više kupaca?\n\nIstaknuti oglasi se prikazuju na samom vrhu kategorije i početne strane sa prepoznatljivim zlatnim bedžem.\n\nOva mogućnost će biti dostupna u narednom ažuriranju sa uvođenjem promotivnih paketa.',
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDesign.radiusXL)),
      ),
      builder: (ctx) => SafeArea(
        child: content(ctx),
      ),
    );
  }
}
