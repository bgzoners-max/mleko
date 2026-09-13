import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Prikazuje banner kada je app offline
class OfflineIndicator extends StatelessWidget {
  final Widget child;

  const OfflineIndicator({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<AppState>().isOffline;

    if (!isOffline) {
      return child;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.orange[700],
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Nemaš internet – Porudžbine će biti poslane kada se povežeš',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Jednostavni offline snackbar kada je app offline
class OfflineSnackBar {
  static void showIfOffline(BuildContext context) {
    final isOffline = context.read<AppState>().isOffline;
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text(
                      'Nemaš internet. Porudžbine će biti poslate automatski.')),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }
}

/// Read-only badge kada je korisnik offline
class OfflineReadOnlyBadge extends StatelessWidget {
  final bool? isOffline;
  const OfflineReadOnlyBadge({super.key, this.isOffline});

  @override
  Widget build(BuildContext context) {
    final effectiveOffline = isOffline ??
        (() {
          try {
            return context.watch<AppState>().isOffline;
          } catch (_) {
            return false;
          }
        })();

    if (!effectiveOffline) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'OFFLINE - samo čitanje',
        style: TextStyle(
          color: Colors.orange[800],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
