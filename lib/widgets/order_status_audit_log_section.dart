import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/responsive.dart';

import 'package:mleko/models/order_status_audit_log_model.dart';
import '../core/ui_strings.dart';
import 'package:mleko/domain/usecases/get_order_status_audit_logs.dart';
import 'app_error_retry.dart';

class OrderStatusAuditLogSection extends StatefulWidget {
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
  State<OrderStatusAuditLogSection> createState() =>
      _OrderStatusAuditLogSectionState();
}

class _OrderStatusAuditLogSectionState
    extends State<OrderStatusAuditLogSection> {
  late Future<List<OrderStatusAuditLogModel>> _future;

  Future<List<OrderStatusAuditLogModel>> _resolveFuture() {
    final loader = widget.logsLoader;
    if (loader != null) {
      return loader(widget.orderId);
    }
    return GetOrderStatusAuditLogsUseCase().call(widget.orderId);
  }

  @override
  void initState() {
    super.initState();
    _future = _resolveFuture();
  }

  @override
  void didUpdateWidget(covariant OrderStatusAuditLogSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        oldWidget.logsLoader != widget.logsLoader) {
      _future = _resolveFuture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderStatusAuditLogModel>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return AppErrorRetry(
            message: 'Greška pri učitavanju istorije statusa.',
            detail: snap.error?.toString(),
            onRetry: () => setState(() => _future = _resolveFuture()),
          );
        }

        if (!snap.hasData) {
          return const SizedBox.shrink();
        }
        final logs = snap.data!;
        if (logs.isEmpty) {
          return const SizedBox.shrink();
        }

        final dateFormat = DateFormat('dd.MM.yyyy. HH:mm', 'sr');
        final isWide = Breakpoints.isTabletOrLarger(context);

        final card = Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(
              widget.title,
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
                      Icon(
                        Icons.history,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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

        if (!isWide) return card;

        return IntrinsicWidth(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 300),
            child: card,
          ),
        );
      },
    );
  }

  String _actorLabel(String role) {
    switch (role) {
      case 'buyer':
        return UiStrings.orderRoleBuyer;
      case 'seller':
        return UiStrings.orderRoleSeller;
      default:
        return UiStrings.orderRoleSystem;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sent':
        return UiStrings.orderStatusSent;
      case 'accepted':
        return UiStrings.orderStatusAccepted;
      case 'shipped':
        return UiStrings.orderStatusShipped;
      case 'delivered':
        return UiStrings.orderStatusDelivered;
      case 'rejected':
        return UiStrings.orderStatusRejected;
      case 'cancelled_by_seller':
        return UiStrings.orderStatusCancelledBySeller;
      case 'arhivirano':
        return UiStrings.orderStatusArchived;
      default:
        return status;
    }
  }
}
