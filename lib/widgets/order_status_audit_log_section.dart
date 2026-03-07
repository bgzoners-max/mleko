import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order_status_audit_log_model.dart';
import '../services/orders_service.dart';

class OrderStatusAuditLogSection extends StatelessWidget {
  final String orderId;
  final String title;
  final Future<List<OrderStatusAuditLogModel>> Function(String orderId)?
      logsLoader;

  const OrderStatusAuditLogSection({
    super.key,
    required this.orderId,
    this.title = 'Istorija statusa',
    this.logsLoader,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderStatusAuditLogModel>>(
      future: (logsLoader ?? OrdersService().getOrderStatusAuditLogs)(orderId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox.shrink();
        }
        final logs = snap.data!;
        if (logs.isEmpty) {
          return const SizedBox.shrink();
        }

        final dateFormat = DateFormat('dd.MM.yyyy. HH:mm', 'sr');
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            subtitle: Text(
              '${logs.length} promena',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            children: [
              for (final log in logs)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.history,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_statusLabel(log.oldStatus)} -> ${_statusLabel(log.newStatus)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_actorLabel(log.changedByRole)} · ${dateFormat.format(log.changedAt.toLocal())}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _actorLabel(String role) {
    switch (role) {
      case 'buyer':
        return 'Kupac';
      case 'seller':
        return 'Prodavac';
      default:
        return 'Sistem';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sent':
        return 'Na cekanju';
      case 'accepted':
        return 'Prihvaceno';
      case 'shipped':
        return 'Poslato';
      case 'delivered':
        return 'Isporuceno';
      case 'rejected':
        return 'Odbijeno';
      case 'cancelled_by_seller':
        return 'Otkazano';
      case 'arhivirano':
        return 'Arhivirano';
      default:
        return status;
    }
  }
}
