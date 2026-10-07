import 'package:flutter/material.dart';

import '../../core/utils/action_utils.dart';
import '../../models/order_model.dart';
import '../../models/seller_delivery_models.dart';
import '../order_delivery_summary.dart';
import 'seller_order_details.dart';

/// Redovi dostave/adrese/telefona porudžbine prodavca.
class SellerOrderDeliveryRows extends StatelessWidget {
  final OrderModel order;

  const SellerOrderDeliveryRows({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Column(
      children: [
        if (!o.hasSellerDelivery)
          SellerOrderDetailRow(
            icon: switch (o.deliveryMethod) {
              DeliveryMethod.courier => Icons.local_shipping,
              DeliveryMethod.pickup => Icons.store,
              _ => Icons.handshake,
            },
            label: 'Dostava',
            value: o.deliveryMethodLabel,
          ),
        if (o.buyerAddress != null && o.buyerAddress!.isNotEmpty)
          SellerOrderDetailRow(
            icon: Icons.location_on,
            label: 'Adresa',
            value: o.buyerAddress!,
          ),
        if (o.buyerCity.isNotEmpty)
          SellerOrderDetailRow(
            icon: Icons.location_city,
            label: 'Grad',
            value: o.buyerCity,
          ),
        if (o.hasSellerDelivery) OrderDeliverySummary(order: o),
        if (o.buyerPhone.isNotEmpty)
          SellerOrderDetailRow(
            icon: Icons.phone,
            label: 'Telefon',
            value: o.buyerPhone,
            trailing: IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: () =>
                  ActionUtils.launchCall(context, o.buyerPhone),
              tooltip: 'Pozovi',
            ),
          ),
      ],
    );
  }
}
