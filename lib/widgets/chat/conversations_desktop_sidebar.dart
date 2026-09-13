import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../models/conversation_model.dart';

class ConversationsDesktopSidebar extends StatelessWidget {
  final List<ConversationModel> list;
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onRefresh;

  const ConversationsDesktopSidebar({
    super.key,
    required this.list,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final favoritesCount = list.where((c) => c.isFavorite).length;
    final unreadCount = list.fold<int>(0, (sum, c) => sum + c.unreadCount);
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
                    'Poruke',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Brz pregled razgovora i nepročitanih poruka.',
                    style: Breakpoints.supportingTextStyle(
                      context,
                      Theme.of(context).textTheme.bodyMedium,
                      phone: 13,
                      largeTabletValue: 14,
                      desktop: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(
                        icon: Icons.chat_bubble_outline,
                        label: 'Ukupno',
                        value: list.length.toString(),
                      ),
                      _StatChip(
                        icon: Icons.star_border,
                        label: 'Omiljeni',
                        value: favoritesCount.toString(),
                      ),
                      _StatChip(
                        icon: Icons.mark_chat_unread_outlined,
                        label: 'Nepročitano',
                        value: unreadCount.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Osveži razgovore'),
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
                    'Prikaz',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SidebarNavTile(
                    icon: Icons.chat_outlined,
                    label: 'Svi razgovori',
                    selected: selectedIndex == 0,
                    onTap: () => onSelectTab(0),
                  ),
                  const SizedBox(height: 8),
                  _SidebarNavTile(
                    icon: Icons.star_border,
                    label: 'Omiljeni',
                    selected: selectedIndex == 1,
                    onTap: () => onSelectTab(1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.10)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon,
                  size: 18, color: selected ? colorScheme.primary : null),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? colorScheme.primary : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text('$label: $value'),
          ],
        ),
      ),
    );
  }
}
