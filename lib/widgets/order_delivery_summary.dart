import 'package:flutter/material.dart';

import '../constants/amazon_theme.dart';
import '../models/order_model.dart';
import '../models/seller_delivery_models.dart';

class OrderDeliverySummary extends StatelessWidget {
  final OrderModel order;

  const OrderDeliverySummary({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    if (!order.hasSellerDelivery) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2F21) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF2E633B) : Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined,
                  size: 18, color: isDark ? AmazonColors.lightGreen : Colors.green.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.deliveryMethodLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AmazonColors.lightGreen : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SummaryLine(label: 'Grad', value: order.deliveryCity ?? ''),
          _SummaryLine(label: 'Mesto', value: order.deliveryPointLabel ?? ''),
          _SummaryLine(label: 'Adresa', value: order.deliveryAddress ?? ''),
          _SummaryLine(
            label: 'Termin',
            value: order.formattedDeliverySchedule ?? '',
          ),
          if (order.deliveryFeeRsd != null)
            _SummaryLine(
              label: 'Dostava',
              value: formatRsdAmount(order.deliveryFeeRsd) ?? '',
            ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
