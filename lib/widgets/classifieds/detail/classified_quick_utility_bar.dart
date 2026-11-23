import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system.dart' show AmazonColors;
import '../../../models/classified_ad_model.dart';
import '../../../providers/app_state.dart';
import '../../../providers/classifieds_provider.dart';
import 'classified_breadcrumbs.dart';

/// Gornja traka za brzi pristup na detaljima malog oglasa (Domaći Market stil):
/// Levo prikazuje breadcrumbs putanju, a desno na desktopu diskretne prečice
/// (`Sačuvani oglasi`, `Sačuvane pretrage`, `Moji oglasi` i orijentacioni kurs evra)
/// bez zauzimanja bočne kolone.
class ClassifiedQuickUtilityBar extends StatelessWidget {
  const ClassifiedQuickUtilityBar({
    super.key,
    required this.ad,
    required this.colorScheme,
    required this.isDark,
    required this.showShortcuts,
  });

  final ClassifiedAdModel ad;
  final ColorScheme colorScheme;
  final bool isDark;
  final bool showShortcuts;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppState? s) => s?.user);
    final savedSearchCount =
        context.select((ClassifiedsProvider? p) => p?.subscriptions.length ?? 0);
    final isLoggedIn = user != null && !user.isGuest;
    final secondaryText =
        isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary;
    final chipBg = isDark
        ? AmazonColors.darkCard
        : AmazonColors.cardWhite;
    final chipBorder =
        isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;

    if (!showShortcuts) {
      return ClassifiedBreadcrumbs(ad: ad, colorScheme: colorScheme);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ClassifiedBreadcrumbs(ad: ad, colorScheme: colorScheme),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _quickPill(
              icon: Icons.favorite_border_rounded,
              label: 'Sačuvani oglasi',
              bg: chipBg,
              border: chipBorder,
              textColor: secondaryText,
              onTap: () => context.push(
                isLoggedIn ? '/favorites?tab=classifieds' : '/login',
              ),
            ),
            if (isLoggedIn) ...[
              _quickPill(
                icon: Icons.notifications_active_outlined,
                label: savedSearchCount > 0
                    ? 'Pretrage ($savedSearchCount)'
                    : 'Pretrage',
                bg: chipBg,
                border: chipBorder,
                textColor: secondaryText,
                onTap: () => context.push('/classifieds/subscriptions'),
              ),
              _quickPill(
                icon: Icons.inventory_2_outlined,
                label: 'Moji oglasi',
                bg: chipBg,
                border: chipBorder,
                textColor: secondaryText,
                onTap: () => context.push('/classifieds/my'),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: chipBorder),
              ),
              child: Text(
                '1 € ≈ ${ClassifiedAdModel.eurToRsdRate.toStringAsFixed(1)} RSD',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: secondaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickPill({
    required IconData icon,
    required String label,
    required Color bg,
    required Color border,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
