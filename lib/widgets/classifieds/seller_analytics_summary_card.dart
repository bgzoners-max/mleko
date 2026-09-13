import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptic.dart';
import '../../models/classified_seller_stats_model.dart';

/// Kartica sa ključnim metrikama učinka (KPI) za prodavca oglasa
class SellerAnalyticsSummaryCard extends StatelessWidget {
  final ClassifiedSellerStatsModel stats;
  final VoidCallback? onRefresh;

  const SellerAnalyticsSummaryCard({
    super.key,
    required this.stats,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Naslov i zaglavlje kartice
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Učinak vaših oglasa',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'Osveži statistiku',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () {
                      AppHaptics.light();
                      onRefresh!();
                    },
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 4 KPI stavke
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildKpiItem(
                      label: 'Pregledi',
                      value: '${stats.totalViews}',
                      icon: Icons.visibility_outlined,
                      iconColor: const Color(0xFF0284C7),
                      isNarrow: isNarrow,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    _buildKpiItem(
                      label: 'Pozivi kupaca',
                      value: '${stats.totalCallClicks}',
                      icon: Icons.phone_in_talk_outlined,
                      iconColor: const Color(0xFF059669),
                      isNarrow: isNarrow,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    _buildKpiItem(
                      label: 'Deljenja',
                      value: '${stats.totalShares}',
                      icon: Icons.share_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      isNarrow: isNarrow,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    _buildKpiItem(
                      label: 'Aktivno / Prodato',
                      value: '${stats.activeAds} / ${stats.soldAds}',
                      icon: Icons.inventory_2_outlined,
                      iconColor: const Color(0xFFD97706),
                      isNarrow: isNarrow,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ),
          ),

          // Najuspešniji oglas (ako postoji)
          if (stats.hasTopAd) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () {
                AppHaptics.light();
                context.push('/classifieds/ad/${stats.topAdId}');
              },
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                      : const Color(0xFFF8FAFC),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Najgledaniji: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        stats.topAdTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${stats.topAdViews} pregleda',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isNarrow,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Container(
      width: isNarrow ? double.infinity : 155,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
