import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system.dart';
import '../../core/utils/error_messages.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/seller_delivery_models.dart';
import 'package:mleko/services/services.dart';
import '../add_review_dialog.dart';
import '../order_delivery_summary.dart';
import '../order_status_audit_log_section.dart';
import '../order_status_timeline.dart';
import 'can_review_order_button.dart';
import 'order_detail_row.dart';
import 'order_items_section.dart';

class BuyerOrderCard extends StatelessWidget {
  final OrderModel order;
  final dynamic user;
  final StreamController<void> refreshController;
  final bool isArchived;

  const BuyerOrderCard({
    super.key,
    required this.order,
    required this.user,
    required this.refreshController,
    this.isArchived = false,
  });

  Future<void> _archiveOrder(BuildContext context) async {
    final ordersService = context.read<OrdersService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arhiviraj porudžbinu?'),
        content: const Text(
          'Arhivirana porudžbina više neće biti u aktivnim porudžbinama.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Arhiviraj'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await ordersService.archiveOrderByBuyer(
      user.id as String,
      order.id,
    );
    refreshController.add(null);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Porudžbina je arhivirana.')),
    );
  }

  Future<void> _confirmReceipt(BuildContext context) async {
    final ordersService = context.read<OrdersService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda prijema'),
        content: const Text(
          'Da li potvrđujete da ste primili porudžbinu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ne'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Da, primio/la sam'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await ordersService.confirmOrderReceivedByBuyer(order.id);
    refreshController.add(null);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prijem porudžbine je potvrđen.')),
    );
  }

  Future<void> _maybeShowReview(BuildContext context) async {
    final reviewsService = context.read<ReviewsService>();
    final ordersService = context.read<OrdersService>();
    final canReview = await reviewsService.canReviewOrder(user.id, order.id);
    if (!context.mounted) return;
    if (!canReview) return;

    String? productId = order.productId;
    String? productName = order.productName;

    // Multi-item porudzbine nemaju product_id na order-u, pa uzimamo prvu stavku.
    if (productId == null ||
        productName == null ||
        productName.trim().isEmpty) {
      final items = await ordersService.getOrderItems(order.id);
      if (items.isNotEmpty) {
        productId = items.first.productId;
        productName = items.first.productName;
      }
    }

    if (!context.mounted) return;
    if (productId == null ||
        productName == null ||
        productName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nije moguće ostaviti recenziju za ovu porudžbinu.')),
      );
      return;
    }

    final resolvedProductId = productId;
    final resolvedProductName = productName;

    await showDialog(
      context: context,
      builder: (ctx) => AddReviewDialog(
        buyerId: user.id,
        sellerId: order.sellerId,
        productId: resolvedProductId,
        orderId: order.id,
        productName: resolvedProductName,
        onSubmitted: () => refreshController.add(null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = order;
    // counterpartyName je batch-učitan u servisu — nema N+1 FutureBuilder
    final sellerName = o.counterpartyName ?? 'Prodavac';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(Icons.store, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/seller/${o.sellerId}'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sellerName,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.person_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                _statusChip(context, o.statusLabel),
              ],
            ),
            const SizedBox(height: 10),
            OrderStatusTimeline(status: o.status),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    switch (o.status) {
                      OrderStatus.sent =>
                        'Porudžbina je poslata – čeka se odgovor prodavca.',
                      OrderStatus.accepted =>
                        'Prodavac je prihvatio porudžbinu – čeka slanje.',
                      OrderStatus.shipped =>
                        'Prodavac je poslao porudžbinu – nakon isporuke potvrdi prijem.',
                      OrderStatus.delivered =>
                        'Porudžbina je isporučena – možeš da je arhiviraš i ostaviš recenziju.',
                      OrderStatus.rejected => 'Prodavac je odbio porudžbinu.',
                      OrderStatus.cancelledBySeller =>
                        'Prodavac je otkazao porudžbinu.',
                      OrderStatus.archived => 'Porudžbina je u arhivi.',
                    },
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OrderStatusAuditLogSection(orderId: o.id),
            if (o.status == OrderStatus.accepted ||
                o.status == OrderStatus.shipped ||
                o.status == OrderStatus.delivered)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          o.status == OrderStatus.delivered
                              ? 'Porudžbina je isporučena'
                              : o.status == OrderStatus.shipped
                                  ? 'Prodavac je označio porudžbinu kao poslatu'
                                  : 'Prodavac je potvrdio porudžbinu',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (o.status == OrderStatus.cancelledBySeller)
              Padding(
                padding: const EdgeInsets.only(top: AppDesign.spaceM),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppDesign.spaceM, vertical: AppDesign.spaceS),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cancel,
                          color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prodavac je otkazao porudžbinu',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            if (o.cancellationReason != null &&
                                o.cancellationReason!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                o.cancellationReason!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange.shade900),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            AppDesign.boxS,
            const Divider(height: 1),
            AppDesign.boxS,
            if (o.hasMultipleItems)
              OrderItemsSection(orderId: o.id)
            else ...[
              OrderDetailRow(
                  icon: Icons.inventory_2,
                  label: 'Proizvod',
                  value: o.productName ?? ''),
              OrderDetailRow(
                  icon: Icons.scale,
                  label: 'Količina',
                  value: ProductModel.formatQuantityWithUnit(
                      o.quantityKg ?? 0, o.unitType ?? ProductModel.unitKg)),
            ],
            if (o.totalAmount != null)
              OrderDetailRow(
                icon: Icons.payments_outlined,
                label: 'Ukupno',
                value: formatRsdAmount(o.totalAmount) ?? '',
              ),
            OrderDetailRow(
              icon: Icons.calendar_today,
              label: 'Datum',
              value: DateFormat('dd.MM.yyyy. HH:mm', 'sr').format(o.createdAt),
            ),
            if (!o.hasSellerDelivery)
              OrderDetailRow(
                icon: switch (o.deliveryMethod) {
                  DeliveryMethod.courier => Icons.local_shipping,
                  DeliveryMethod.pickup => Icons.store,
                  _ => Icons.handshake,
                },
                label: 'Dostava',
                value: o.deliveryMethodLabel,
              ),
            if (o.buyerAddress != null && o.buyerAddress!.isNotEmpty)
              OrderDetailRow(
                  icon: Icons.location_on,
                  label: 'Adresa',
                  value: o.buyerAddress!),
            if (o.buyerCity.isNotEmpty)
              OrderDetailRow(
                  icon: Icons.location_city,
                  label: 'Grad',
                  value: o.buyerCity),
            if (o.hasSellerDelivery) OrderDeliverySummary(order: o),
            if (o.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Napomena',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                              const SizedBox(height: 2),
                              Text(o.note,
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final convId =
                          await context.read<ChatService>().getOrCreateConversation(
                        user.id,
                        o.sellerId,
                        orderId: o.id,
                        productId: o.productId,
                      );
                      if (context.mounted) unawaited(context.push('/chat/$convId'));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(friendlyError(e)),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Poruka prodavcu'),
                ),
                if (o.status == OrderStatus.delivered ||
                    o.status == OrderStatus.archived)
                  CanReviewOrderButton(
                    key: ValueKey('canreview-${o.id}'),
                    userId: user.id,
                    order: o,
                    onPressed: () => _maybeShowReview(context),
                  ),
                if (!isArchived && o.status == OrderStatus.shipped)
                  FilledButton.icon(
                    onPressed: () => _confirmReceipt(context),
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('Potvrdi prijem'),
                  ),
                if (!isArchived && o.canBuyerManuallyArchive)
                  FilledButton.tonalIcon(
                    onPressed: () => _archiveOrder(context),
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text('Arhiviraj'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String label) {
    final color = switch (label) {
      'Na čekanju' => Colors.orange,
      'Poslato' => Colors.teal,
      'Prihvaćeno' => Colors.blue,
      'Odbijeno' => Colors.red,
      'Isporučeno' => Colors.green,
      'Otkazano' => Colors.grey,
      'Arhivirano' => Colors.brown,
      _ => Colors.grey,
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color),
    );
  }
}
