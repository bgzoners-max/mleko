import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';

class SellerLoyaltyStats {
  final int repeatOrders;
  final int repeatBuyers;

  const SellerLoyaltyStats({
    required this.repeatOrders,
    required this.repeatBuyers,
  });

  factory SellerLoyaltyStats.fromJson(Map<String, dynamic> json) {
    return SellerLoyaltyStats(
      repeatOrders: (json['repeat_orders'] as num?)?.toInt() ?? 0,
      repeatBuyers: (json['repeat_buyers'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasAnyLoyalty => repeatOrders > 0 && repeatBuyers > 0;
}

class SellerSafetyStrip extends StatefulWidget {
  final UserModel seller;

  const SellerSafetyStrip({super.key, required this.seller});

  @override
  State<SellerSafetyStrip> createState() => _SellerSafetyStripState();
}

class _SellerSafetyStripState extends State<SellerSafetyStrip> {
  late final Future<SellerLoyaltyStats> _loyaltyFuture = _loadLoyalty();

  Future<SellerLoyaltyStats> _loadLoyalty() async {
    try {
      final client = Supabase.instance.client;
      final result = await client.rpc(
        'get_seller_loyalty_stats',
        params: {'p_seller_id': widget.seller.id},
      );
      if (result == null) {
        return const SellerLoyaltyStats(repeatOrders: 0, repeatBuyers: 0);
      }
      final map = result is Map<String, dynamic>
          ? result
          : Map<String, dynamic>.from(result as Map);
      return SellerLoyaltyStats.fromJson(map);
    } catch (_) {
      return const SellerLoyaltyStats(repeatOrders: 0, repeatBuyers: 0);
    }
  }

  static String? _repeatLabel(SellerLoyaltyStats stats) {
    if (!stats.hasAnyLoyalty) return null;
    final n = stats.repeatOrders;
    if (n == 1) return '1 ponovljena kupovina od istih kupaca';
    if (n >= 2 && n <= 4) return '$n ponovljene kupovine od istih kupaca';
    return '$n ponovljenih kupovina od istih kupaca';
  }

  @override
  Widget build(BuildContext context) {
    final seller = widget.seller;
    final isVerified = seller.isVerified;

    return FutureBuilder<SellerLoyaltyStats>(
      future: _loyaltyFuture,
      builder: (context, snap) {
        final stats = snap.data;
        final repeat = stats != null ? _repeatLabel(stats) : null;

        if (!isVerified && repeat == null) {
          return const SizedBox.shrink();
        }

        final children = <Widget>[];

        if (isVerified) {
          children.add(
            SellerReputationItem(
              icon: Icons.verified,
              iconColor: Theme.of(context).colorScheme.primary,
              title: 'Provereno gazdinstvo',
              value: 'Dokumenta i podaci su provereni',
            ),
          );
        }

        if (repeat != null) {
          children.add(
            SellerReputationItem(
              icon: Icons.repeat_outlined,
              iconColor: Colors.green.shade700,
              title: 'Lojalni kupci',
              value: repeat,
            ),
          );
        }

        if (children.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: w,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class SellerReputationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const SellerReputationItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
