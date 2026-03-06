import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Widget koji pokazuje cache status - prikazuje kada podaci dolaze iz cache-a
class CacheStatusIndicator extends StatelessWidget {
  final VoidCallback? onRefresh;

  const CacheStatusIndicator({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<AppState>().isOffline;

    if (!isOffline) return const SizedBox.shrink();

    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.cached, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prikazujem sačuvane podatke',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Osvežiti'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

/// Banner koji se prikazuje na vrhu kada korisnik pregleda proizvode offline
class OfflineBrowsingBanner extends StatelessWidget {
  const OfflineBrowsingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<AppState>().isOffline;

    if (!isOffline) return const SizedBox.shrink();

    return Material(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.wifi_off, size: 20, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Offline pregledanje',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  Text(
                    'Podaci su iz memorije. Porudžbine će biti poslate kada se internet vrati.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
