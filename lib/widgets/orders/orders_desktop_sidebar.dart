import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import 'orders_sidebar_tile.dart';
import 'orders_status_filter_bar.dart';

class OrdersDesktopSidebar extends StatelessWidget {
  final int segmentIndex;
  final ValueChanged<int> onSegmentChanged;
  final int statusChipIndex;
  final ValueChanged<int> onStatusChipChanged;
  final String segmentDescription;
  final VoidCallback onRefresh;

  const OrdersDesktopSidebar({
    super.key,
    required this.segmentIndex,
    required this.onSegmentChanged,
    required this.statusChipIndex,
    required this.onStatusChipChanged,
    required this.segmentDescription,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = Breakpoints.cardPadding(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Porudžbine',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    segmentDescription,
                    style: Breakpoints.supportingTextStyle(
                      context,
                      Theme.of(context).textTheme.bodyMedium,
                      phone: 13,
                      largeTabletValue: 14,
                      desktop: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Osveži prikaz'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: Breakpoints.panelGap(context)),
          Card(
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sekcije',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OrdersSidebarTile(
                    icon: Icons.receipt_long,
                    label: 'U toku',
                    selected: segmentIndex == 0,
                    onTap: () => onSegmentChanged(0),
                  ),
                  const SizedBox(height: 8),
                  OrdersSidebarTile(
                    icon: Icons.archive_outlined,
                    label: 'Arhiva',
                    selected: segmentIndex == 1,
                    onTap: () => onSegmentChanged(1),
                  ),
                  const SizedBox(height: 8),
                  OrdersSidebarTile(
                    icon: Icons.store,
                    label: 'Prodavci',
                    selected: segmentIndex == 2,
                    onTap: () => onSegmentChanged(2),
                  ),
                ],
              ),
            ),
          ),
          if (segmentIndex == 0) ...[
            SizedBox(height: Breakpoints.panelGap(context)),
            Card(
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Status filter',
                      style: Breakpoints.sectionTitleStyle(
                        context,
                        Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OrderStatusFilterChips(
                      statusChipIndex: statusChipIndex,
                      onStatusChipChanged: onStatusChipChanged,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
