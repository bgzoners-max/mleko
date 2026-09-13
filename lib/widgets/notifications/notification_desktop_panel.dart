import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../models/notification_model.dart';
import '../app_empty_state.dart';
import 'notification_card.dart';

class NotificationDesktopPanel extends StatelessWidget {
  final List<NotificationModel> list;
  final void Function(NotificationModel n) onDelete;
  final void Function(NotificationModel n)? onTap;
  final double? tileVerticalPadding;
  final double? tileHorizontalPadding;
  final double? tileBottomMargin;

  const NotificationDesktopPanel({
    super.key,
    required this.list,
    required this.onDelete,
    this.onTap,
    this.tileVerticalPadding,
    this.tileHorizontalPadding,
    this.tileBottomMargin,
  });

  @override
  Widget build(BuildContext context) {
    final panelPadding = Breakpoints.cardPadding(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              panelPadding,
              panelPadding,
              panelPadding,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sva obaveštenja',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      '${list.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: AppEmptyState(
                      icon: Icons.notifications_none,
                      title: 'Nemate obaveštenja',
                      subtitle:
                          'Ovde će se prikazivati porudžbine, poruke i ostala obaveštenja.',
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(panelPadding),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final n = list[i];
                      return NotificationCard(
                        notification: n,
                        onDelete: () => onDelete(n),
                        onTap: onTap != null ? () => onTap!(n) : null,
                        tileHorizontalPadding: tileHorizontalPadding,
                        tileVerticalPadding: tileVerticalPadding,
                        tileBottomMargin: tileBottomMargin,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
