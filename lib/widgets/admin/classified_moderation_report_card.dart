import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/classified_report_model.dart';

/// Kartica pojedinačne prijave oglasa u admin moderaciji.
class ClassifiedModerationReportCard extends StatelessWidget {
  final ClassifiedAdReportModel report;
  final ValueChanged<ClassifiedAdReportModel> onDeactivate;
  final void Function(ClassifiedAdReportModel report, String action) onModerateAction;

  const ClassifiedModerationReportCard({
    super.key,
    required this.report,
    required this.onDeactivate,
    required this.onModerateAction,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}.${dt.month}.${dt.year}.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = report.statusColor;
    final hasMultipleReports = (report.adReportsCount ?? 0) > 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: report.isPending
              ? Colors.orange.shade300
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gornji red: status prijave + broj prijava za ovaj oglas
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    report.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hasMultipleReports) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_rounded,
                            size: 13, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${report.adReportsCount} prijave za oglas',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDate(report.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Podaci o oglasu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail slike
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: colorScheme.surfaceContainerHighest,
                    child: report.adImages.isNotEmpty
                        ? Image.network(
                            report.adImages.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                              size: 24,
                            ),
                          )
                        : const Icon(Icons.campaign_outlined, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.adTitle ?? 'Oglas: ${report.adId}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (report.adPrice != null) ...[
                        Text(
                          '${report.adPrice!.toStringAsFixed(0)} ${report.adCurrency ?? 'RSD'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                      if (report.adStatus != null) ...[
                        Text(
                          'Status oglasa: ${report.adStatus}',
                          style: TextStyle(
                            fontSize: 11,
                            color: report.adStatus == 'rejected'
                                ? Colors.red.shade700
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Razlog prijave
            Row(
              children: [
                Icon(
                  ClassifiedReportReason.iconFor(report.reason),
                  size: 16,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ClassifiedReportReason.labelFor(report.reason),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),

            // Detalji koje je korisnik upisao
            if (report.details != null && report.details!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '"${report.details!}"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            if (report.reporterName != null) ...[
              const SizedBox(height: 6),
              Text(
                'Prijavio: ${report.reporterName}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Dugmad za akciju
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/classifieds/ad/${report.adId}'),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Pogledaj oglas'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (report.isPending) ...[
                  FilledButton.icon(
                    onPressed: () => onDeactivate(report),
                    icon: const Icon(Icons.block_rounded, size: 16),
                    label: const Text('Ukloni oglas'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onModerateAction(report, 'resolve_reviewed'),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Ispravan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onModerateAction(report, 'dismiss'),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Odbaci prijavu'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
