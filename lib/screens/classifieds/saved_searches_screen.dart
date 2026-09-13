import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/responsive.dart';
import '../../models/classified_subscription_model.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../../widgets/app_empty_state.dart';

/// Ekran za pregled i upravljanje sačuvanim pretragama i praćenim kategorijama oglasa.
class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({super.key});

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassifiedsProvider>().loadSubscriptions();
    });
  }

  Future<void> _handleDelete(
    BuildContext context,
    ClassifiedsProvider classifieds,
    ClassifiedSubscriptionModel sub,
  ) async {
    AppHaptics.selection();
    final name = sub.categoryName ?? 'ovu pretragu';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Otkaži praćenje?'),
        content: Text(
          'Da li ste sigurni da više ne želite obaveštenja za „$name”?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Otkaži praćenje'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await classifieds.removeSubscription(sub.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Otkazano praćenje za „$name”.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openSubscription(
    BuildContext context,
    ClassifiedsProvider classifieds,
    ClassifiedSubscriptionModel sub,
  ) {
    AppHaptics.light();
    if (sub.categoryId.isNotEmpty) {
      classifieds.selectCategory(sub.categoryId);
    } else {
      classifieds.selectCategory(null);
    }

    if (sub.searchQuery != null && sub.searchQuery!.isNotEmpty) {
      classifieds.search(sub.searchQuery);
    } else {
      classifieds.search(null);
    }

    context.go('/classifieds');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final classifieds = context.watch<ClassifiedsProvider>();
    final user = context.watch<AppState>().user;

    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Praćene kategorije')),
        body: const Center(
          child: Text('Prijavite se da biste videli praćene kategorije.'),
        ),
      );
    }

    final items = classifieds.subscriptions;
    final isDesktop = Breakpoints.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Praćene kategorije i pretrage'),
            if (items.isNotEmpty)
              Text(
                '${items.length} ${items.length == 1 ? 'stavka' : 'stavke'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.maxContentWidth(context),
          ),
          child: RefreshIndicator(
            onRefresh: classifieds.loadSubscriptions,
            child: items.isEmpty
                ? AppEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'Nemate praćenih kategorija',
                    subtitle:
                        'Pratite kategorije u oglasniku i automatski primajte obaveštenja čim neko postavi novi oglas.',
                    ctaLabel: 'Istraži oglase',
                    ctaIcon: Icons.explore_outlined,
                    onCtaPressed: () => context.go('/classifieds'),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16,
                      vertical: 12,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, idx) {
                      final sub = items[idx];
                      final cat = sub.categoryId.isNotEmpty
                          ? classifieds.findCategory(sub.categoryId)
                          : null;
                      final catIcon = cat?.iconData ?? Icons.notifications_active_outlined;
                      final summary = sub.criteriaSummary;
                      final dateStr = DateFormat('dd.MM.yyyy.').format(sub.createdAt);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _openSubscription(context, classifieds, sub),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    catIcon,
                                    color: colorScheme.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.categoryName ?? 'Sve kategorije',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (summary.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            summary,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        'Praćeno od $dateStr',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Otkaži obaveštenja',
                                  icon: Icon(
                                    Icons.notifications_active_rounded,
                                    color: colorScheme.primary,
                                    size: 22,
                                  ),
                                  onPressed: () => _handleDelete(context, classifieds, sub),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
