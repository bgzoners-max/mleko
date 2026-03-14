import 'package:flutter/material.dart';

import '../models/order_model.dart';

class OrderStatusTimeline extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusTimeline({super.key, required this.status});

  static const _labels = [
    'Na čekanju',
    'Prihvaćeno',
    'Poslato',
    'Isporučeno',
  ];

  int get _activeIndex => switch (status) {
        OrderStatus.sent => 0,
        OrderStatus.accepted => 1,
        OrderStatus.shipped => 2,
        OrderStatus.delivered => 3,
        OrderStatus.archived => 3,
        OrderStatus.rejected => 1,
        OrderStatus.cancelledBySeller => 1,
      };

  bool get _isStopped =>
      status == OrderStatus.rejected || status == OrderStatus.cancelledBySeller;

  String get _statusHint {
    switch (status) {
      case OrderStatus.sent:
        return 'Čeka se potvrda porudžbine.';
      case OrderStatus.accepted:
        return 'Sad je na potezu prodavac – priprema tvoju porudžbinu za slanje.';
      case OrderStatus.shipped:
        return 'Prodavac je poslao porudžbinu – sačekaj isporuku i onda potvrdi prijem.';
      case OrderStatus.delivered:
        return 'Sad si ti na potezu – potvrdi da si primio porudžbinu.';
      case OrderStatus.cancelledBySeller:
        return 'Prodavac je otkazao porudžbinu – ako ti nešto nije jasno, javi se prodavcu.';
      case OrderStatus.rejected:
        return 'Prodavac je odbio porudžbinu – kontaktiraj ga ako želiš dodatno objašnjenje.';
      case OrderStatus.archived:
        return 'Porudžbina je uspešno završena.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        _isStopped ? Colors.red.shade600 : Colors.green.shade700;
    final inactiveColor = Colors.grey.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _labels.length; i++) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: i <= _activeIndex ? activeColor : Colors.white,
                  border: Border.all(
                    color: i <= _activeIndex ? activeColor : inactiveColor,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: i <= _activeIndex
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (i < _labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < _activeIndex ? activeColor : inactiveColor,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < _labels.length; i++) ...[
              Expanded(
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        i <= _activeIndex ? FontWeight.w600 : FontWeight.w400,
                    color: i <= _activeIndex
                        ? Colors.grey.shade800
                        : Colors.grey.shade500,
                  ),
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == _labels.length - 1
                          ? TextAlign.right
                          : TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _statusHint,
          style: TextStyle(
            fontSize: 12,
            color: _isStopped ? Colors.red.shade700 : Colors.grey.shade800,
            fontWeight: _isStopped ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
