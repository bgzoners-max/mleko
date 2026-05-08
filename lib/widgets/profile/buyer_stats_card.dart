import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../core/design_system.dart';
import '../../services/services.dart';

class BuyerStatsCard extends StatefulWidget {
  final UserModel user;
  const BuyerStatsCard({super.key, required this.user});

  @override
  State<BuyerStatsCard> createState() => _BuyerStatsCardState();
}

class _BuyerStatsCardState extends State<BuyerStatsCard> {
  late final Future<BuyerStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = context.read<OrdersService>().getBuyerStats(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BuyerStats>(
      future: _statsFuture,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final stats = snap.data!;
        
        // Prikaži samo ako ima šta da se prikaže
        if (stats.totalSuccessCount == 0 && stats.pendingCount == 0) {
          return const SizedBox.shrink();
        }

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go('/conversations'), // Ili na neku posebnu stranu za porudžbine ako postoji (npr /orders)
            child: Padding(
              padding: AppDesign.paddingM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.green.shade800,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Moje kupovine',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  AppDesign.boxM,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatColumn(
                        label: 'Isporučeno',
                        value: stats.totalSuccessCount.toString(),
                        icon: Icons.check_circle_outline,
                        color: Colors.green.shade700,
                      ),
                      StatColumn(
                        label: 'Na čekanju',
                        value: stats.pendingCount.toString(),
                        icon: Icons.hourglass_bottom,
                        color: Colors.orange.shade700,
                      ),
                      StatColumn(
                        label: 'Potrošeno',
                        value: '${stats.totalSpent.toStringAsFixed(0)} RSD',
                        icon: Icons.account_balance_wallet_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatColumn({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
