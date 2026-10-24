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

class BuyerOrderCard extends StatefulWidget {
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

  @override
  State<BuyerOrderCard> createState() => _BuyerOrderCardState();
}

class _BuyerOrderCardState extends State<BuyerOrderCard> {
  bool _isExpanded = false;

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
      widget.user.id as String,
      widget.order.id,
    );
    widget.refreshController.add(null);
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

    await ordersService.confirmOrderReceivedByBuyer(widget.order.id);
    widget.refreshController.add(null);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prijem porudžbine je potvrđen.')),
    );
  }

  Future<void> _maybeShowReview(BuildContext context) async {
    final reviewsService = context.read<ReviewsService>();
    final ordersService = context.read<OrdersService>();
    final canReview =
        await reviewsService.canReviewOrder(widget.user.id, widget.order.id);
    if (!context.mounted) return;
    if (!canReview) return;

    String? productId = widget.order.productId;
    String? productName = widget.order.productName;

    // Multi-item porudzbine nemaju product_id na order-u, pa uzimamo prvu stavku.
    if (productId == null ||
        productName == null ||
        productName.trim().isEmpty) {
      final items = await ordersService.getOrderItems(widget.order.id);
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
        buyerId: widget.user.id,
        sellerId: widget.order.sellerId,
        productId: resolvedProductId,
        orderId: widget.order.id,
        productName: resolvedProductName,
        onSubmitted: () => widget.refreshController.add(null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final sellerName = o.counterpartyName ?? 'Prodavac';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ZAGLAVLJE: Prodavac, Datum, Iznos i Status bedž
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isDark
                        ? const Color(0xFF1B2F21)
                        : Colors.green.shade50,
                    child: Icon(Icons.storefront_outlined,
                        size: 16, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => context.push('/seller/${o.sellerId}'),
                          child: Text(
                            sellerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  fontSize: 13,
                                ),
                          ),
                        ),
                        Text(
                          '#${o.id.substring(0, 8)} · ${DateFormat('dd.MM.yyyy. HH:mm', 'sr').format(o.createdAt)}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (o.totalAmount != null) ...[
                    Text(
                      formatRsdAmount(o.totalAmount) ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF81C784)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _statusChip(context, o.statusLabel),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 2. SAŽETAK PROIZVODA I DOSTAVE
              Row(
                children: [
                  Icon(
                    o.hasMultipleItems
                        ? Icons.inventory_2_outlined
                        : Icons.shopping_basket_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      o.hasMultipleItems
                          ? (o.productName != null && o.productName!.isNotEmpty
                              ? o.productName!
                              : 'Više naručenih proizvoda')
                          : '${o.productName ?? 'Proizvod'} · ${ProductModel.formatQuantityWithUnit(o.quantityKg ?? 0, o.unitType ?? ProductModel.unitKg)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          switch (o.deliveryMethod) {
                            DeliveryMethod.courier =>
                              Icons.local_shipping_outlined,
                            DeliveryMethod.pickup => Icons.store_outlined,
                            _ => Icons.handshake_outlined,
                          },
                          size: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          o.deliveryMethodLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 3. SKLOPIVI DETALJI (Timeline, Audit log, Baneri, Adresa, Napomena, Svi artikli)
              if (_isExpanded) ...[
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 8),
                OrderStatusTimeline(status: o.status),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
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
                          OrderStatus.rejected =>
                            'Prodavac je odbio porudžbinu.',
                          OrderStatus.cancelledBySeller =>
                            'Prodavac je otkazao porudžbinu.',
                          OrderStatus.archived =>
                            'Porudžbina je u arhivi.',
                        },
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                OrderStatusAuditLogSection(orderId: o.id),
                if (o.status == OrderStatus.accepted ||
                    o.status == OrderStatus.shipped ||
                    o.status == OrderStatus.delivered)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B2F21)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: isDark
                                ? const Color(0xFF2E633B)
                                : Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: isDark
                                  ? AmazonColors.lightGreen
                                  : Colors.green.shade700,
                              size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              o.status == OrderStatus.delivered
                                  ? 'Porudžbina je isporučena'
                                  : o.status == OrderStatus.shipped
                                      ? 'Prodavac je označio porudžbinu kao poslatu'
                                      : 'Prodavac je potvrdio porudžbinu',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isDark
                                    ? AmazonColors.lightGreen
                                    : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (o.status == OrderStatus.cancelledBySeller)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.cancel,
                              color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prodavac je otkazao porudžbinu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                if (o.cancellationReason != null &&
                                    o.cancellationReason!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    o.cancellationReason!,
                                    style: TextStyle(
                                        fontSize: 11,
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
                const SizedBox(height: 6),
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
                          o.quantityKg ?? 0,
                          o.unitType ?? ProductModel.unitKg)),
                ],
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Napomena: ${o.note}',
                            style: const TextStyle(
                                fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              // 4. BRZE AKCIJE
              const SizedBox(height: 6),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () async {
                      try {
                        final convId = await context
                            .read<ChatService>()
                            .getOrCreateConversation(
                          widget.user.id,
                          o.sellerId,
                          orderId: o.id,
                          productId: o.productId,
                        );
                        if (context.mounted) {
                          unawaited(context.push('/chat/$convId'));
                        }
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
                    icon: const Icon(Icons.chat_outlined, size: 14),
                    label:
                        const Text('Poruka', style: TextStyle(fontSize: 11)),
                  ),
                  if (o.status == OrderStatus.delivered ||
                      o.status == OrderStatus.archived) ...[
                    const SizedBox(width: 6),
                    CanReviewOrderButton(
                      key: ValueKey('canreview-${o.id}'),
                      userId: widget.user.id,
                      order: o,
                      onPressed: () => _maybeShowReview(context),
                    ),
                  ],
                  if (!widget.isArchived &&
                      o.status == OrderStatus.shipped) ...[
                    const SizedBox(width: 6),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 28),
                      ),
                      onPressed: () => _confirmReceipt(context),
                      icon: const Icon(Icons.verified_outlined, size: 14),
                      label: const Text('Potvrdi prijem',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  if (!widget.isArchived && o.canBuyerManuallyArchive) ...[
                    const SizedBox(width: 6),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 28),
                      ),
                      onPressed: () => _archiveOrder(context),
                      icon: const Icon(Icons.archive_outlined, size: 14),
                      label: const Text('Arhiviraj',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  const SizedBox(width: 4),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 0),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () =>
                        setState(() => _isExpanded = !_isExpanded),
                    child: Text(
                      _isExpanded ? 'Manje' : 'Detalji',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
