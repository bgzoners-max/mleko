import 'package:flutter/material.dart';

class OrdersSegmentedControl extends StatelessWidget {
  final int segmentIndex;
  final ValueChanged<int> onSegmentChanged;

  const OrdersSegmentedControl({
    super.key,
    required this.segmentIndex,
    required this.onSegmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          label: Text('U toku'),
          icon: Icon(Icons.receipt_long),
        ),
        ButtonSegment(
          value: 1,
          label: Text('Arhiva'),
          icon: Icon(Icons.archive_outlined),
        ),
        ButtonSegment(
          value: 2,
          label: Text('Prodavci'),
          icon: Icon(Icons.store),
        ),
      ],
      selected: {segmentIndex},
      onSelectionChanged: (selection) => onSegmentChanged(selection.first),
    );
  }
}

class OrderStatusFilterChips extends StatelessWidget {
  final int statusChipIndex;
  final ValueChanged<int> onStatusChipChanged;

  const OrderStatusFilterChips({
    super.key,
    required this.statusChipIndex,
    required this.onStatusChipChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Sve'),
          selected: statusChipIndex == 0,
          onSelected: (_) => onStatusChipChanged(0),
        ),
        FilterChip(
          label: const Text('Čeka prodavca'),
          selected: statusChipIndex == 1,
          onSelected: (_) => onStatusChipChanged(1),
        ),
        FilterChip(
          label: const Text('Prihvaćene'),
          selected: statusChipIndex == 2,
          onSelected: (_) => onStatusChipChanged(2),
        ),
        FilterChip(
          label: const Text('Poslate'),
          selected: statusChipIndex == 3,
          onSelected: (_) => onStatusChipChanged(3),
        ),
        FilterChip(
          label: const Text('Odbijene'),
          selected: statusChipIndex == 4,
          onSelected: (_) => onStatusChipChanged(4),
        ),
      ],
    );
  }
}
