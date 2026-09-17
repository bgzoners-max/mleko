import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design_system.dart';
import '../../providers/app_state.dart';
import '../../services/orders/sync_manager.dart';

/// Banner koji obaveštava korisnika o porudžbinama kreiranim u offline režimu
/// koje čekaju sinhronizaciju sa serverom, uz prikaz grešaka i retry brojača.
class PendingOrdersBanner extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final SyncManager? syncManager;

  const PendingOrdersBanner({super.key, this.margin, this.syncManager});

  @override
  Widget build(BuildContext context) {
    final manager = syncManager ?? context.watch<AppState>().syncManager;

    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final pendingOrders = manager.pendingOrders;
        if (pendingOrders.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

    final count = pendingOrders.length;
    final maxRetries = pendingOrders
        .map((o) => o.retryCount)
        .fold(0, (max, cur) => cur > max ? cur : max);
    final hasErrors = maxRetries > 0;

    // Pronađi najskoriju grešku ako postoji
    final latestError = pendingOrders
        .where((o) => o.lastError != null && o.lastError!.isNotEmpty)
        .map((o) => o.lastError!)
        .lastOrNull;

    final backgroundColor = hasErrors
        ? (isDark ? const Color(0xFF3E2723) : const Color(0xFFFFF3E0))
        : (isDark ? const Color(0xFF1B2A38) : const Color(0xFFE3F2FD));

    final borderColor = hasErrors
        ? (isDark ? Colors.orange.shade800 : Colors.orange.shade300)
        : (isDark ? Colors.blue.shade800 : Colors.blue.shade300);

    final titleColor = hasErrors
        ? (isDark ? Colors.orange.shade200 : Colors.orange.shade900)
        : (isDark ? Colors.blue.shade200 : Colors.blue.shade900);

    final textColor = hasErrors
        ? (isDark ? Colors.orange.shade300 : Colors.orange.shade800)
        : (isDark ? Colors.blue.shade300 : Colors.blue.shade800);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDesign.radiusM),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                hasErrors
                    ? Icons.sync_problem_rounded
                    : Icons.cloud_queue_rounded,
                color: titleColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  count == 1
                      ? '1 porudžbina čeka slanje na server'
                      : '$count porudžbine čekaju slanje na server',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              if (manager.isSyncing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: () => manager.syncPendingOrders(),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Pošalji sada',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pendingOrders
                .map((o) => '${o.productName} (${o.quantityKg} ${o.unitType})')
                .join(', '),
            style: TextStyle(fontSize: 13, color: textColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasErrors) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: titleColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    latestError != null
                        ? 'Pokušano $maxRetries puta: $latestError'
                        : 'Neuspešnih pokušaja slanja: $maxRetries',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
      },
    );
  }
}
